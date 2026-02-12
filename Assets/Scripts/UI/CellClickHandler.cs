using UnityEngine;

namespace NeoOthello.UI
{
    /// <summary>
    /// Attached to each board cell to handle mouse click input.
    /// </summary>
    public class CellClickHandler : MonoBehaviour
    {
        private int _row;
        private int _col;
        private BoardUI _boardUI;

        public void Initialize(int row, int col, BoardUI boardUI)
        {
            _row = row;
            _col = col;
            _boardUI = boardUI;
        }

        private void OnMouseDown()
        {
            if (_boardUI != null)
            {
                _boardUI.OnCellClicked(_row, _col);
            }
        }
    }
}
