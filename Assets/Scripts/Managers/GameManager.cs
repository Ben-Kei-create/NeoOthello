using UnityEngine;
using NeoOthello.Core;
using NeoOthello.Data;
using NeoOthello.AI;
using NeoOthello.UI;

namespace NeoOthello.Managers
{
    /// <summary>
    /// Top-level game orchestrator. Initializes all systems and starts the game.
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private BoardUI _boardUI;
        [SerializeField] private HandUI _handUI;
        [SerializeField] private GameUI _gameUI;

        [Header("Settings")]
        [SerializeField] private GameMode _gameMode = GameMode.Classic;

        private BoardLogic _board;
        private DeckManager _deck;
        private HandManager _blackHand;
        private HandManager _whiteHand;
        private TurnManager _turnManager;
        private AIPlayer _ai;

        public static GameManager Instance { get; private set; }
        public GameMode CurrentMode => _gameMode;
        public BoardLogic Board => _board;
        public TurnManager TurnManager => _turnManager;
        public HandManager BlackHand => _blackHand;
        public HandManager WhiteHand => _whiteHand;
        public DeckManager Deck => _deck;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
        }

        private void Start()
        {
            InitializeGame(_gameMode);
        }

        public void InitializeGame(GameMode mode)
        {
            _gameMode = mode;

            // Core logic
            _board = new BoardLogic();
            _board.InitStandardBoard();

            // AI (always White)
            _ai = new AIPlayer(DiscColor.White);

            // Deck & Hands (only used in Rogue mode, but initialized for safety)
            _deck = new DeckManager();
            _blackHand = new HandManager(DiscColor.Black);
            _whiteHand = new HandManager(DiscColor.White);

            if (mode == GameMode.Rogue)
            {
                _deck.BuildDeck();
            }

            // Turn Manager
            if (_turnManager == null)
            {
                _turnManager = gameObject.AddComponent<TurnManager>();
            }
            _turnManager.Initialize(_board, _deck, _blackHand, _whiteHand, _ai, mode);

            // UI setup
            SetupUI();

            // Subscribe to events
            BindEvents();

            // Start the game
            _turnManager.StartGame();
        }

        private void SetupUI()
        {
            if (_boardUI != null)
            {
                _boardUI.Initialize(_board, _turnManager);
            }

            if (_handUI != null)
            {
                _handUI.gameObject.SetActive(_gameMode == GameMode.Rogue);
                if (_gameMode == GameMode.Rogue)
                {
                    _handUI.Initialize(_blackHand, _turnManager);
                }
            }

            if (_gameUI != null)
            {
                _gameUI.Initialize(this);
            }
        }

        private void BindEvents()
        {
            _turnManager.OnDiscPlaced += HandleDiscPlaced;
            _turnManager.OnGameOver += HandleGameOver;
            _turnManager.OnTurnStarted += HandleTurnStarted;
            _turnManager.OnLimitBreak += HandleLimitBreak;
            _turnManager.OnTurnSkipped += HandleTurnSkipped;
            _turnManager.OnHackedForcePlacement += HandleHackedForce;
        }

        private void HandleDiscPlaced(int row, int col, DiscColor color, int flipped)
        {
            if (_boardUI != null)
                _boardUI.RefreshBoard();

            if (_gameUI != null)
                _gameUI.UpdateInfo();
        }

        private void HandleTurnStarted(DiscColor player)
        {
            if (_gameUI != null)
                _gameUI.UpdateTurnIndicator(player);
        }

        private void HandleGameOver(DiscColor winner, int blackCount, int whiteCount)
        {
            if (_gameUI != null)
                _gameUI.ShowGameOver(winner, blackCount, whiteCount);
        }

        private void HandleLimitBreak(DiscColor player, int newCapacity)
        {
            if (_gameUI != null)
                _gameUI.ShowLimitBreak(player, newCapacity);

            if (_handUI != null && player == DiscColor.Black)
                _handUI.RefreshSlots();
        }

        private void HandleTurnSkipped(DiscColor player)
        {
            if (_gameUI != null)
                _gameUI.ShowTurnSkipped(player);
        }

        private void HandleHackedForce(int row, int col)
        {
            if (_gameUI != null)
                _gameUI.ShowHackedEffect(row, col);
        }

        public void RestartGame()
        {
            StopAllCoroutines();
            InitializeGame(_gameMode);
        }

        public void ChangeMode(GameMode mode)
        {
            StopAllCoroutines();
            InitializeGame(mode);
        }
    }
}
