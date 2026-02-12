using System.Collections.Generic;
using NeoOthello.Core;
using NeoOthello.Data;

namespace NeoOthello.Effects
{
    /// <summary>
    /// Resolves special disc effects after placement.
    /// </summary>
    public static class DiscEffectResolver
    {
        /// <summary>
        /// Apply post-placement effect for a disc.
        /// Returns a list of affected cells for UI animation purposes.
        /// </summary>
        public static List<BoardCell> Resolve(BoardLogic board, int row, int col,
            DiscType type, DiscColor placerColor)
        {
            return type switch
            {
                DiscType.Bomb => ResolveBomb(board, row, col, placerColor),
                _ => new List<BoardCell>()
            };
        }

        /// <summary>
        /// Bomb: Destroy all enemy-colored discs in the surrounding 8 cells.
        /// </summary>
        private static List<BoardCell> ResolveBomb(BoardLogic board, int row, int col,
            DiscColor placerColor)
        {
            var affected = new List<BoardCell>();
            DiscColor enemy = BoardLogic.Opponent(placerColor);

            var adjacent = board.GetAdjacentCells(row, col);
            foreach (var cell in adjacent)
            {
                if (cell.Color == enemy)
                {
                    affected.Add(cell);
                    board.DestroyCell(cell.Row, cell.Col);
                }
            }

            return affected;
        }
    }
}
