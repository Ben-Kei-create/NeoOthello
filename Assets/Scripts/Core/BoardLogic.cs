using System.Collections.Generic;
using NeoOthello.Data;

namespace NeoOthello.Core
{
    /// <summary>
    /// Pure logic for 8x8 Othello board. No Unity dependencies.
    /// Handles placement validation, flipping, and move enumeration.
    /// </summary>
    public class BoardLogic
    {
        public const int BoardSize = 8;

        private static readonly int[] DirRow = { -1, -1, -1, 0, 0, 1, 1, 1 };
        private static readonly int[] DirCol = { -1, 0, 1, -1, 1, -1, 0, 1 };

        private BoardCell[,] _cells;

        public BoardCell[,] Cells => _cells;

        public BoardLogic()
        {
            _cells = new BoardCell[BoardSize, BoardSize];
            for (int r = 0; r < BoardSize; r++)
            {
                for (int c = 0; c < BoardSize; c++)
                {
                    _cells[r, c] = new BoardCell(r, c);
                }
            }
        }

        /// <summary>
        /// Set up standard Othello initial 4 pieces.
        /// </summary>
        public void InitStandardBoard()
        {
            ClearBoard();
            _cells[3, 3].Place(DiscColor.White);
            _cells[3, 4].Place(DiscColor.Black);
            _cells[4, 3].Place(DiscColor.Black);
            _cells[4, 4].Place(DiscColor.White);
        }

        public void ClearBoard()
        {
            for (int r = 0; r < BoardSize; r++)
                for (int c = 0; c < BoardSize; c++)
                    _cells[r, c].Clear();
        }

        public BoardCell GetCell(int row, int col)
        {
            if (!InBounds(row, col)) return null;
            return _cells[row, col];
        }

        public bool InBounds(int row, int col)
        {
            return row >= 0 && row < BoardSize && col >= 0 && col < BoardSize;
        }

        /// <summary>
        /// Returns the list of cells that would be flipped if 'color' places at (row, col).
        /// Empty list means the move is invalid.
        /// </summary>
        public List<BoardCell> GetFlippableCells(int row, int col, DiscColor color)
        {
            var result = new List<BoardCell>();
            if (!InBounds(row, col) || !_cells[row, col].IsEmpty)
                return result;

            DiscColor opponent = Opponent(color);

            for (int d = 0; d < 8; d++)
            {
                var line = new List<BoardCell>();
                int r = row + DirRow[d];
                int c = col + DirCol[d];

                while (InBounds(r, c) && _cells[r, c].Color == opponent)
                {
                    line.Add(_cells[r, c]);
                    r += DirRow[d];
                    c += DirCol[d];
                }

                if (line.Count > 0 && InBounds(r, c) && _cells[r, c].Color == color)
                {
                    result.AddRange(line);
                }
            }

            return result;
        }

        /// <summary>
        /// Check if a move is valid.
        /// </summary>
        public bool IsValidMove(int row, int col, DiscColor color)
        {
            return GetFlippableCells(row, col, color).Count > 0;
        }

        /// <summary>
        /// Place a disc and flip. Returns the number of flipped discs.
        /// </summary>
        public int PlaceDisc(int row, int col, DiscColor color, DiscType type = DiscType.Normal)
        {
            var flippable = GetFlippableCells(row, col, color);
            if (flippable.Count == 0) return 0;

            _cells[row, col].Place(color, type);

            foreach (var cell in flippable)
            {
                cell.Flip();
            }

            return flippable.Count;
        }

        /// <summary>
        /// Get all valid moves for a color.
        /// </summary>
        public List<(int row, int col)> GetValidMoves(DiscColor color)
        {
            var moves = new List<(int, int)>();
            for (int r = 0; r < BoardSize; r++)
            {
                for (int c = 0; c < BoardSize; c++)
                {
                    if (IsValidMove(r, c, color))
                        moves.Add((r, c));
                }
            }
            return moves;
        }

        /// <summary>
        /// Check if neither player can move (game over).
        /// </summary>
        public bool IsGameOver()
        {
            return GetValidMoves(DiscColor.Black).Count == 0
                && GetValidMoves(DiscColor.White).Count == 0;
        }

        /// <summary>
        /// Count discs of each color.
        /// </summary>
        public (int black, int white) CountDiscs()
        {
            int b = 0, w = 0;
            for (int r = 0; r < BoardSize; r++)
            {
                for (int c = 0; c < BoardSize; c++)
                {
                    if (_cells[r, c].Color == DiscColor.Black) b++;
                    else if (_cells[r, c].Color == DiscColor.White) w++;
                }
            }
            return (b, w);
        }

        /// <summary>
        /// Destroy (clear) a cell. Used by Bomb effect.
        /// </summary>
        public void DestroyCell(int row, int col)
        {
            if (InBounds(row, col))
                _cells[row, col].Clear();
        }

        /// <summary>
        /// Get cells adjacent to (row, col).
        /// </summary>
        public List<BoardCell> GetAdjacentCells(int row, int col)
        {
            var adj = new List<BoardCell>();
            for (int d = 0; d < 8; d++)
            {
                int r = row + DirRow[d];
                int c = col + DirCol[d];
                if (InBounds(r, c))
                    adj.Add(_cells[r, c]);
            }
            return adj;
        }

        public static DiscColor Opponent(DiscColor color)
        {
            return color == DiscColor.Black ? DiscColor.White : DiscColor.Black;
        }
    }
}
