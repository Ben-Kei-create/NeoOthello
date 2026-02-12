namespace NeoOthello.Data
{
    /// <summary>
    /// Represents one cell on the 8x8 board.
    /// </summary>
    public class BoardCell
    {
        public int Row;
        public int Col;
        public DiscColor Color;
        public DiscType PlacedType;
        public bool IsEmpty => Color == DiscColor.None;

        public BoardCell(int row, int col)
        {
            Row = row;
            Col = col;
            Color = DiscColor.None;
            PlacedType = DiscType.Normal;
        }

        public void Place(DiscColor color, DiscType type = DiscType.Normal)
        {
            Color = color;
            PlacedType = type;
        }

        public void Flip()
        {
            if (Color == DiscColor.Black) Color = DiscColor.White;
            else if (Color == DiscColor.White) Color = DiscColor.Black;
        }

        public void Clear()
        {
            Color = DiscColor.None;
            PlacedType = DiscType.Normal;
        }
    }
}
