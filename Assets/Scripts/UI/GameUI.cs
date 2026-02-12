using UnityEngine;
using UnityEngine.UI;
using NeoOthello.Data;
using NeoOthello.Managers;

namespace NeoOthello.UI
{
    /// <summary>
    /// Manages HUD elements: turn indicator, score, deck count, messages.
    /// </summary>
    public class GameUI : MonoBehaviour
    {
        [Header("UI References")]
        [SerializeField] private Text _turnIndicatorText;
        [SerializeField] private Text _scoreText;
        [SerializeField] private Text _deckCountText;
        [SerializeField] private Text _handCapacityText;
        [SerializeField] private Text _messageText;
        [SerializeField] private GameObject _gameOverPanel;
        [SerializeField] private Text _gameOverText;
        [SerializeField] private Button _restartButton;
        [SerializeField] private Button _titleButton;

        private GameManager _gameManager;

        public void Initialize(GameManager gameManager)
        {
            _gameManager = gameManager;

            if (_restartButton != null)
                _restartButton.onClick.AddListener(OnRestartClicked);

            if (_titleButton != null)
                _titleButton.onClick.AddListener(OnTitleClicked);

            if (_gameOverPanel != null)
                _gameOverPanel.SetActive(false);

            // Hide Rogue-only UI in Classic mode
            if (_gameManager.CurrentMode == GameMode.Classic)
            {
                if (_deckCountText != null) _deckCountText.gameObject.SetActive(false);
                if (_handCapacityText != null) _handCapacityText.gameObject.SetActive(false);
            }
            else
            {
                if (_deckCountText != null) _deckCountText.gameObject.SetActive(true);
                if (_handCapacityText != null) _handCapacityText.gameObject.SetActive(true);
            }

            UpdateInfo();
        }

        public void UpdateTurnIndicator(DiscColor player)
        {
            if (_turnIndicatorText != null)
            {
                string name = player == DiscColor.Black ? "Black (You)" : "White (AI)";
                _turnIndicatorText.text = $"Turn: {name}";
            }

            ClearMessage();
        }

        public void UpdateInfo()
        {
            if (_gameManager == null) return;

            var (black, white) = _gameManager.Board.CountDiscs();

            if (_scoreText != null)
                _scoreText.text = $"Black: {black}  |  White: {white}";

            if (_gameManager.CurrentMode == GameMode.Rogue)
            {
                if (_deckCountText != null)
                    _deckCountText.text = $"Deck: {_gameManager.Deck.RemainingCount}";

                if (_handCapacityText != null)
                    _handCapacityText.text = $"Hand: {_gameManager.BlackHand.CurrentCount}/{_gameManager.BlackHand.HandCapacity}";
            }
        }

        public void ShowGameOver(DiscColor winner, int blackCount, int whiteCount)
        {
            if (_gameOverPanel != null)
                _gameOverPanel.SetActive(true);

            if (_gameOverText != null)
            {
                string result = winner switch
                {
                    DiscColor.Black => "You Win!",
                    DiscColor.White => "AI Wins!",
                    _ => "Draw!"
                };
                _gameOverText.text = $"{result}\nBlack: {blackCount} - White: {whiteCount}";
            }
        }

        public void ShowLimitBreak(DiscColor player, int newCapacity)
        {
            string name = player == DiscColor.Black ? "You" : "AI";
            ShowMessage($"LIMIT BREAK! {name} hand capacity -> {newCapacity}!");
        }

        public void ShowTurnSkipped(DiscColor player)
        {
            string name = player == DiscColor.Black ? "Black" : "White";
            ShowMessage($"{name} has no valid moves. Turn skipped.");
        }

        public void ShowHackedEffect(int row, int col)
        {
            ShowMessage($"HACKED! Forced placement at ({row}, {col})!");
        }

        public void ShowMessage(string msg)
        {
            if (_messageText != null)
                _messageText.text = msg;
        }

        public void ClearMessage()
        {
            if (_messageText != null)
                _messageText.text = "";
        }

        private void OnRestartClicked()
        {
            if (_gameOverPanel != null)
                _gameOverPanel.SetActive(false);

            _gameManager.RestartGame();
        }

        private void OnTitleClicked()
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene("TitleScene");
        }
    }
}
