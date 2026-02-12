using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using NeoOthello.Data;

namespace NeoOthello.UI
{
    /// <summary>
    /// Title screen with mode selection buttons.
    /// </summary>
    public class TitleScreen : MonoBehaviour
    {
        [Header("UI References")]
        [SerializeField] private Text _titleText;
        [SerializeField] private Button _classicButton;
        [SerializeField] private Button _rogueButton;
        [SerializeField] private Text _classicLabel;
        [SerializeField] private Text _rogueLabel;
        [SerializeField] private Text _descriptionText;

        // Static field to pass mode selection to the game scene
        public static GameMode SelectedMode { get; private set; } = GameMode.Classic;

        private void Start()
        {
            if (_titleText != null)
                _titleText.text = "Neo Othello";

            if (_classicLabel != null)
                _classicLabel.text = "Classic Mode";

            if (_rogueLabel != null)
                _rogueLabel.text = "Rogue Mode";

            if (_descriptionText != null)
                _descriptionText.text = "Select a game mode";

            if (_classicButton != null)
            {
                _classicButton.onClick.AddListener(OnClassicClicked);
            }

            if (_rogueButton != null)
            {
                _rogueButton.onClick.AddListener(OnRogueClicked);
            }
        }

        private void OnClassicClicked()
        {
            SelectedMode = GameMode.Classic;
            if (_descriptionText != null)
                _descriptionText.text = "Standard 8x8 Reversi. Pure strategy.";

            LoadGameScene();
        }

        private void OnRogueClicked()
        {
            SelectedMode = GameMode.Rogue;
            if (_descriptionText != null)
                _descriptionText.text = "Deck-building Othello with special discs!";

            LoadGameScene();
        }

        private void LoadGameScene()
        {
            SceneManager.LoadScene("GameScene");
        }
    }
}
