using System.Collections.Generic;
using NeoOthello.Core;
using NeoOthello.Data;

namespace NeoOthello.AI
{
    /// <summary>
    /// AI player using positional evaluation for move selection.
    /// </summary>
    public class AIPlayer
    {
        // Positional weight table: corners are highly valuable, edges are good,
        // cells adjacent to corners (X-squares, C-squares) are dangerous.
        private static readonly int[,] PositionWeights = {
            { 100, -20,  10,   5,   5,  10, -20, 100 },
            { -20, -50,  -2,  -2,  -2,  -2, -50, -20 },
            {  10,  -2,   1,   1,   1,   1,  -2,  10 },
            {   5,  -2,   1,   0,   0,   1,  -2,   5 },
            {   5,  -2,   1,   0,   0,   1,  -2,   5 },
            {  10,  -2,   1,   1,   1,   1,  -2,  10 },
            { -20, -50,  -2,  -2,  -2,  -2, -50, -20 },
            { 100, -20,  10,   5,   5,  10, -20, 100 }
        };

        private DiscColor _aiColor;

        public AIPlayer(DiscColor color)
        {
            _aiColor = color;
        }

        /// <summary>
        /// Choose the best move for Classic mode (pure Othello).
        /// Uses positional evaluation + flip count.
        /// </summary>
        public (int row, int col) ChooseBestMove(BoardLogic board)
        {
            var validMoves = board.GetValidMoves(_aiColor);
            if (validMoves.Count == 0)
                return (-1, -1);

            (int row, int col) bestMove = validMoves[0];
            int bestScore = int.MinValue;

            foreach (var (r, c) in validMoves)
            {
                int score = EvaluateMove(board, r, c, _aiColor);
                if (score > bestScore)
                {
                    bestScore = score;
                    bestMove = (r, c);
                }
            }

            return bestMove;
        }

        /// <summary>
        /// For Hacked disc: choose the worst move for the opponent
        /// (i.e., the best move for the AI's perspective).
        /// </summary>
        public (int row, int col) ChooseWorstMoveFor(BoardLogic board, DiscColor victimColor)
        {
            var validMoves = board.GetValidMoves(victimColor);
            if (validMoves.Count == 0)
                return (-1, -1);

            DiscColor beneficiary = BoardLogic.Opponent(victimColor);

            (int row, int col) worstMove = validMoves[0];
            int worstScore = int.MaxValue;

            foreach (var (r, c) in validMoves)
            {
                // Score from the victim's perspective - pick the lowest scoring move
                int score = EvaluateMove(board, r, c, victimColor);
                if (score < worstScore)
                {
                    worstScore = score;
                    worstMove = (r, c);
                }
            }

            return worstMove;
        }

        /// <summary>
        /// Choose a random valid move (used for Hacked disc when AI is victim).
        /// </summary>
        public (int row, int col) ChooseRandomMove(BoardLogic board, DiscColor color)
        {
            var validMoves = board.GetValidMoves(color);
            if (validMoves.Count == 0) return (-1, -1);
            int idx = UnityEngine.Random.Range(0, validMoves.Count);
            return validMoves[idx];
        }

        /// <summary>
        /// Choose which hand disc to play (Rogue mode AI).
        /// Prefers Normal discs for good positions, saves special discs.
        /// </summary>
        public int ChooseHandDisc(IReadOnlyList<DiscData> hand, BoardLogic board)
        {
            // Simple heuristic: prefer Normal, then Bomb, avoid playing Hacked on self
            int bestIdx = 0;
            int bestPriority = -1;

            for (int i = 0; i < hand.Count; i++)
            {
                int priority = hand[i].Type switch
                {
                    DiscType.Normal => 10,
                    DiscType.Bomb => 5,
                    DiscType.Hacked => 1, // AI avoids playing Hacked on itself
                    _ => 0
                };

                if (priority > bestPriority)
                {
                    bestPriority = priority;
                    bestIdx = i;
                }
            }

            return bestIdx;
        }

        private int EvaluateMove(BoardLogic board, int row, int col, DiscColor color)
        {
            int flipCount = board.GetFlippableCells(row, col, color).Count;
            int positionValue = PositionWeights[row, col];
            return positionValue * 2 + flipCount;
        }
    }
}
