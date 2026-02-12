using UnityEngine;
using NeoOthello.Core;
using NeoOthello.Data;
using NeoOthello.Managers;

namespace NeoOthello.UI
{
    /// <summary>
    /// Renders the 8x8 board and handles cell click input.
    /// Creates the board using primitive GameObjects (Quads for cells, Cylinders for discs).
    /// </summary>
    public class BoardUI : MonoBehaviour
    {
        [Header("Board Settings")]
        [SerializeField] private float _cellSize = 1.0f;
        [SerializeField] private float _discHeight = 0.2f;
        [SerializeField] private Color _boardColor = new Color(0.0f, 0.5f, 0.0f);
        [SerializeField] private Color _validMoveHighlight = new Color(0.3f, 0.7f, 0.3f, 0.8f);

        [Header("Materials")]
        [SerializeField] private Material _blackDiscMat;
        [SerializeField] private Material _whiteDiscMat;

        private BoardLogic _board;
        private TurnManager _turnManager;
        private GameObject[,] _cellObjects;
        private GameObject[,] _discObjects;
        private GameObject[,] _highlightObjects;
        private Transform _boardRoot;

        public void Initialize(BoardLogic board, TurnManager turnManager)
        {
            _board = board;
            _turnManager = turnManager;
            BuildBoardVisuals();
            RefreshBoard();
        }

        private void BuildBoardVisuals()
        {
            // Clean up existing board
            if (_boardRoot != null)
                Destroy(_boardRoot.gameObject);

            _boardRoot = new GameObject("BoardRoot").transform;
            _boardRoot.SetParent(transform);
            _boardRoot.localPosition = Vector3.zero;

            _cellObjects = new GameObject[BoardLogic.BoardSize, BoardLogic.BoardSize];
            _discObjects = new GameObject[BoardLogic.BoardSize, BoardLogic.BoardSize];
            _highlightObjects = new GameObject[BoardLogic.BoardSize, BoardLogic.BoardSize];

            float offset = (BoardLogic.BoardSize - 1) * _cellSize * 0.5f;

            for (int r = 0; r < BoardLogic.BoardSize; r++)
            {
                for (int c = 0; c < BoardLogic.BoardSize; c++)
                {
                    Vector3 pos = new Vector3(
                        c * _cellSize - offset,
                        0,
                        (BoardLogic.BoardSize - 1 - r) * _cellSize - offset
                    );

                    // Cell background (Quad)
                    var cell = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    cell.name = $"Cell_{r}_{c}";
                    cell.transform.SetParent(_boardRoot);
                    cell.transform.localPosition = pos;
                    cell.transform.localRotation = Quaternion.Euler(90, 0, 0);
                    cell.transform.localScale = Vector3.one * _cellSize * 0.95f;

                    var cellRenderer = cell.GetComponent<Renderer>();
                    cellRenderer.material = new Material(Shader.Find("Standard"));
                    cellRenderer.material.color = _boardColor;

                    // Add click handler component
                    var clickHandler = cell.AddComponent<CellClickHandler>();
                    clickHandler.Initialize(r, c, this);

                    _cellObjects[r, c] = cell;

                    // Highlight overlay (slightly above cell)
                    var highlight = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    highlight.name = $"Highlight_{r}_{c}";
                    highlight.transform.SetParent(_boardRoot);
                    highlight.transform.localPosition = pos + Vector3.up * 0.01f;
                    highlight.transform.localRotation = Quaternion.Euler(90, 0, 0);
                    highlight.transform.localScale = Vector3.one * _cellSize * 0.9f;

                    var hlRenderer = highlight.GetComponent<Renderer>();
                    hlRenderer.material = new Material(Shader.Find("Standard"));
                    hlRenderer.material.color = _validMoveHighlight;
                    SetMaterialTransparent(hlRenderer.material);

                    // Remove collider from highlight so it doesn't interfere with clicks
                    var hlCollider = highlight.GetComponent<Collider>();
                    if (hlCollider != null) Destroy(hlCollider);

                    highlight.SetActive(false);
                    _highlightObjects[r, c] = highlight;
                }
            }

            // Create grid lines border
            CreateBoardBorder(offset);
        }

        private void CreateBoardBorder(float offset)
        {
            var border = new GameObject("BoardBorder");
            border.transform.SetParent(_boardRoot);

            // Simple frame using thin cubes
            float boardWidth = BoardLogic.BoardSize * _cellSize;
            float thickness = 0.05f;

            CreateBorderLine(border.transform, new Vector3(-offset - _cellSize * 0.5f, 0, 0),
                new Vector3(thickness, thickness, boardWidth));
            CreateBorderLine(border.transform, new Vector3(offset + _cellSize * 0.5f, 0, 0),
                new Vector3(thickness, thickness, boardWidth));
            CreateBorderLine(border.transform, new Vector3(0, 0, -offset - _cellSize * 0.5f),
                new Vector3(boardWidth, thickness, thickness));
            CreateBorderLine(border.transform, new Vector3(0, 0, offset + _cellSize * 0.5f),
                new Vector3(boardWidth, thickness, thickness));
        }

        private void CreateBorderLine(Transform parent, Vector3 pos, Vector3 scale)
        {
            var line = GameObject.CreatePrimitive(PrimitiveType.Cube);
            line.transform.SetParent(parent);
            line.transform.localPosition = pos;
            line.transform.localScale = scale;
            line.GetComponent<Renderer>().material.color = Color.black;
            var col = line.GetComponent<Collider>();
            if (col != null) Destroy(col);
        }

        public void RefreshBoard()
        {
            if (_board == null) return;

            float offset = (BoardLogic.BoardSize - 1) * _cellSize * 0.5f;

            for (int r = 0; r < BoardLogic.BoardSize; r++)
            {
                for (int c = 0; c < BoardLogic.BoardSize; c++)
                {
                    // Remove old disc
                    if (_discObjects[r, c] != null)
                    {
                        Destroy(_discObjects[r, c]);
                        _discObjects[r, c] = null;
                    }

                    var cell = _board.GetCell(r, c);
                    if (!cell.IsEmpty)
                    {
                        Vector3 pos = new Vector3(
                            c * _cellSize - offset,
                            _discHeight * 0.5f,
                            (BoardLogic.BoardSize - 1 - r) * _cellSize - offset
                        );

                        var disc = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                        disc.name = $"Disc_{r}_{c}";
                        disc.transform.SetParent(_boardRoot);
                        disc.transform.localPosition = pos;
                        disc.transform.localScale = new Vector3(
                            _cellSize * 0.4f,
                            _discHeight * 0.5f,
                            _cellSize * 0.4f
                        );

                        var renderer = disc.GetComponent<Renderer>();

                        // Create material based on color
                        if (cell.Color == DiscColor.Black)
                        {
                            if (_blackDiscMat != null)
                                renderer.material = _blackDiscMat;
                            else
                                renderer.material.color = Color.black;
                        }
                        else
                        {
                            if (_whiteDiscMat != null)
                                renderer.material = _whiteDiscMat;
                            else
                                renderer.material.color = Color.white;
                        }

                        // Remove collider from disc
                        var discCollider = disc.GetComponent<Collider>();
                        if (discCollider != null) Destroy(discCollider);

                        _discObjects[r, c] = disc;
                    }
                }
            }

            UpdateValidMoveHighlights();
        }

        private void UpdateValidMoveHighlights()
        {
            if (_turnManager == null || _board == null) return;

            // Only show highlights during Place phase when it's the human's turn
            bool showHighlights = _turnManager.CurrentPhase == TurnPhase.Place
                && _turnManager.CurrentPlayer == DiscColor.Black
                && _turnManager.IsWaitingForInput;

            var validMoves = showHighlights
                ? _board.GetValidMoves(DiscColor.Black)
                : new System.Collections.Generic.List<(int, int)>();

            for (int r = 0; r < BoardLogic.BoardSize; r++)
            {
                for (int c = 0; c < BoardLogic.BoardSize; c++)
                {
                    bool isValid = validMoves.Contains((r, c));
                    if (_highlightObjects[r, c] != null)
                        _highlightObjects[r, c].SetActive(isValid);
                }
            }
        }

        public void OnCellClicked(int row, int col)
        {
            if (_turnManager == null) return;
            _turnManager.OnPlayerPlaceDisc(row, col);
        }

        private void Update()
        {
            // Continuously update highlights to reflect current state
            UpdateValidMoveHighlights();
        }

        private void SetMaterialTransparent(Material mat)
        {
            mat.SetFloat("_Mode", 3); // Transparent
            mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            mat.SetInt("_ZWrite", 0);
            mat.DisableKeyword("_ALPHATEST_ON");
            mat.EnableKeyword("_ALPHABLEND_ON");
            mat.DisableKeyword("_ALPHAPREMULTIPLY_ON");
            mat.renderQueue = 3000;
        }
    }
}
