using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NeoOthello.Core;
using NeoOthello.Data;
using NeoOthello.AI;
using NeoOthello.Effects;

namespace NeoOthello.Managers
{
    /// <summary>
    /// Manages the turn flow. Adapts phase sequence based on GameMode.
    /// Classic: StartTurn -> Place -> EndTurn
    /// Rogue:   StartTurn -> Draw -> SelectHand -> Place -> Effect -> EndTurn
    /// </summary>
    public class TurnManager : MonoBehaviour
    {
        private BoardLogic _board;
        private DeckManager _deck;
        private HandManager _blackHand;
        private HandManager _whiteHand;
        private AIPlayer _ai;
        private GameMode _mode;

        private DiscColor _currentPlayer;
        private TurnPhase _currentPhase;
        private DiscData _selectedDisc;
        private bool _waitingForInput;
        private bool _gameOver;
        private int _lastPlacedRow = -1;
        private int _lastPlacedCol = -1;

        public DiscColor CurrentPlayer => _currentPlayer;
        public TurnPhase CurrentPhase => _currentPhase;
        public bool IsWaitingForInput => _waitingForInput;
        public bool IsGameOver => _gameOver;
        public DiscData SelectedDisc => _selectedDisc;

        // Events for UI
        public event Action<DiscColor> OnTurnStarted;
        public event Action<TurnPhase> OnPhaseChanged;
        public event Action<int, int, DiscColor, int> OnDiscPlaced; // row, col, color, flipped
        public event Action<List<BoardCell>> OnEffectResolved;
        public event Action<DiscColor, int> OnLimitBreak; // player, newCapacity
        public event Action<DiscColor, int, int> OnGameOver; // winner, blackCount, whiteCount
        public event Action<DiscColor> OnTurnSkipped;
        public event Action<int, int> OnHackedForcePlacement; // row, col forced by hacked

        public void Initialize(BoardLogic board, DeckManager deck,
            HandManager blackHand, HandManager whiteHand,
            AIPlayer ai, GameMode mode)
        {
            _board = board;
            _deck = deck;
            _blackHand = blackHand;
            _whiteHand = whiteHand;
            _ai = ai;
            _mode = mode;
            _currentPlayer = DiscColor.Black; // Black goes first
            _gameOver = false;
        }

        /// <summary>
        /// Start the first turn.
        /// </summary>
        public void StartGame()
        {
            _gameOver = false;
            StartCoroutine(ExecuteTurn());
        }

        private IEnumerator ExecuteTurn()
        {
            while (!_gameOver)
            {
                // Check if current player has valid moves
                var validMoves = _board.GetValidMoves(_currentPlayer);
                if (validMoves.Count == 0)
                {
                    // Check if opponent can move
                    var opponentMoves = _board.GetValidMoves(BoardLogic.Opponent(_currentPlayer));
                    if (opponentMoves.Count == 0)
                    {
                        // Game over
                        EndGame();
                        yield break;
                    }
                    // Skip turn
                    OnTurnSkipped?.Invoke(_currentPlayer);
                    yield return new WaitForSeconds(0.5f);
                    SwitchPlayer();
                    continue;
                }

                // === START TURN ===
                SetPhase(TurnPhase.StartTurn);
                OnTurnStarted?.Invoke(_currentPlayer);
                yield return new WaitForSeconds(0.3f);

                if (_mode == GameMode.Rogue)
                {
                    // === DRAW PHASE ===
                    SetPhase(TurnPhase.Draw);
                    yield return DrawPhase();

                    // === SELECT HAND PHASE ===
                    SetPhase(TurnPhase.SelectHand);
                    yield return SelectHandPhase();
                }
                else
                {
                    // Classic mode: use a default Normal disc
                    _selectedDisc = new DiscData(DiscType.Normal, _currentPlayer);
                }

                // === PLACE PHASE ===
                SetPhase(TurnPhase.Place);
                yield return PlacePhase();

                if (_mode == GameMode.Rogue)
                {
                    // === EFFECT PHASE ===
                    SetPhase(TurnPhase.Effect);
                    yield return EffectPhase();
                }

                // === END TURN ===
                SetPhase(TurnPhase.EndTurn);

                // Check game over via deck + board
                if (_board.IsGameOver() || (_mode == GameMode.Rogue && _deck.IsEmpty
                    && GetCurrentHand().CurrentCount == 0
                    && GetOpponentHand().CurrentCount == 0))
                {
                    EndGame();
                    yield break;
                }

                SwitchPlayer();
                yield return null;
            }
        }

        private IEnumerator DrawPhase()
        {
            HandManager hand = GetCurrentHand();

            while (!hand.IsFull && !_deck.IsEmpty)
            {
                DiscData drawn = _deck.Draw(_currentPlayer);
                if (drawn != null)
                {
                    hand.AddToHand(drawn);
                    yield return new WaitForSeconds(0.15f);
                }
            }
        }

        private IEnumerator SelectHandPhase()
        {
            HandManager hand = GetCurrentHand();

            if (hand.CurrentCount == 0)
            {
                // No discs to select - use a dummy normal disc
                _selectedDisc = new DiscData(DiscType.Normal, _currentPlayer);
                yield break;
            }

            if (_currentPlayer == DiscColor.Black)
            {
                // Human player: wait for input
                _waitingForInput = true;
                _selectedDisc = null;

                while (_selectedDisc == null)
                {
                    yield return null;
                }

                _waitingForInput = false;
            }
            else
            {
                // AI: choose disc from hand
                int idx = _ai.ChooseHandDisc(hand.Hand, _board);
                _selectedDisc = hand.RemoveFromHand(idx);
                yield return new WaitForSeconds(0.3f);
            }
        }

        /// <summary>
        /// Called by UI when human player selects a hand disc (Rogue mode).
        /// </summary>
        public void OnPlayerSelectHandDisc(int index)
        {
            if (_currentPhase != TurnPhase.SelectHand || !_waitingForInput) return;

            HandManager hand = GetCurrentHand();
            _selectedDisc = hand.RemoveFromHand(index);
        }

        private IEnumerator PlacePhase()
        {
            bool isHacked = _selectedDisc != null && _selectedDisc.Type == DiscType.Hacked;

            if (isHacked)
            {
                yield return HackedPlacement();
            }
            else if (_currentPlayer == DiscColor.Black)
            {
                // Human: wait for board click
                yield return WaitForHumanPlacement();
            }
            else
            {
                // AI: choose best move
                yield return AIPlacement();
            }
        }

        private IEnumerator WaitForHumanPlacement()
        {
            _waitingForInput = true;

            while (_waitingForInput)
            {
                yield return null;
            }
        }

        /// <summary>
        /// Called by UI when human clicks a valid cell on the board.
        /// </summary>
        public void OnPlayerPlaceDisc(int row, int col)
        {
            if (_currentPhase != TurnPhase.Place || !_waitingForInput) return;

            if (!_board.IsValidMove(row, col, _currentPlayer)) return;

            DiscType type = _selectedDisc?.Type ?? DiscType.Normal;
            int flipped = _board.PlaceDisc(row, col, _currentPlayer, type);
            _lastPlacedRow = row;
            _lastPlacedCol = col;
            OnDiscPlaced?.Invoke(row, col, _currentPlayer, flipped);

            if (_mode == GameMode.Rogue)
            {
                CheckLimitBreak(flipped);
            }

            _waitingForInput = false;
        }

        private IEnumerator AIPlacement()
        {
            yield return new WaitForSeconds(0.5f);

            var move = _ai.ChooseBestMove(_board);
            if (move.row < 0) yield break;

            DiscType type = _selectedDisc?.Type ?? DiscType.Normal;
            int flipped = _board.PlaceDisc(move.row, move.col, _currentPlayer, type);
            _lastPlacedRow = move.row;
            _lastPlacedCol = move.col;
            OnDiscPlaced?.Invoke(move.row, move.col, _currentPlayer, flipped);

            if (_mode == GameMode.Rogue)
            {
                CheckLimitBreak(flipped);
            }
        }

        private IEnumerator HackedPlacement()
        {
            // Hacked disc: the opponent controls placement
            if (_currentPlayer == DiscColor.Black)
            {
                // Player used Hacked -> AI picks the worst move for Black
                yield return new WaitForSeconds(0.5f);
                var move = _ai.ChooseWorstMoveFor(_board, DiscColor.Black);
                if (move.row >= 0)
                {
                    int flipped = _board.PlaceDisc(move.row, move.col, _currentPlayer, DiscType.Hacked);
                    _lastPlacedRow = move.row;
                    _lastPlacedCol = move.col;
                    OnHackedForcePlacement?.Invoke(move.row, move.col);
                    OnDiscPlaced?.Invoke(move.row, move.col, _currentPlayer, flipped);
                }
            }
            else
            {
                // AI used Hacked -> random/beneficial placement for Black
                yield return new WaitForSeconds(0.5f);
                var move = _ai.ChooseRandomMove(_board, DiscColor.White);
                if (move.row >= 0)
                {
                    int flipped = _board.PlaceDisc(move.row, move.col, _currentPlayer, DiscType.Hacked);
                    _lastPlacedRow = move.row;
                    _lastPlacedCol = move.col;
                    OnHackedForcePlacement?.Invoke(move.row, move.col);
                    OnDiscPlaced?.Invoke(move.row, move.col, _currentPlayer, flipped);
                }
            }
        }

        private IEnumerator EffectPhase()
        {
            if (_selectedDisc == null || _selectedDisc.Type == DiscType.Normal)
                yield break;

            // Hacked is already resolved during Place phase
            if (_selectedDisc.Type == DiscType.Bomb && _lastPlacedRow >= 0)
            {
                yield return new WaitForSeconds(0.3f);
                var affected = DiscEffectResolver.Resolve(
                    _board, _lastPlacedRow, _lastPlacedCol,
                    DiscType.Bomb, _currentPlayer);
                if (affected.Count > 0)
                {
                    OnEffectResolved?.Invoke(affected);
                }
            }
        }

        private void CheckLimitBreak(int flippedCount)
        {
            HandManager hand = GetCurrentHand();
            if (hand.CheckLimitBreak(flippedCount))
            {
                if (hand.TryExpandCapacity())
                {
                    OnLimitBreak?.Invoke(_currentPlayer, hand.HandCapacity);

                    // Immediate bonus draw
                    if (!_deck.IsEmpty)
                    {
                        DiscData bonus = _deck.Draw(_currentPlayer);
                        if (bonus != null)
                        {
                            hand.AddToHand(bonus);
                        }
                    }
                }
            }
        }

        private void SetPhase(TurnPhase phase)
        {
            _currentPhase = phase;
            OnPhaseChanged?.Invoke(phase);
        }

        private void SwitchPlayer()
        {
            _currentPlayer = BoardLogic.Opponent(_currentPlayer);
        }

        private HandManager GetCurrentHand()
        {
            return _currentPlayer == DiscColor.Black ? _blackHand : _whiteHand;
        }

        private HandManager GetOpponentHand()
        {
            return _currentPlayer == DiscColor.Black ? _whiteHand : _blackHand;
        }

        private void EndGame()
        {
            _gameOver = true;
            var (black, white) = _board.CountDiscs();
            DiscColor winner = black > white ? DiscColor.Black
                : white > black ? DiscColor.White
                : DiscColor.None;
            OnGameOver?.Invoke(winner, black, white);
        }
    }
}
