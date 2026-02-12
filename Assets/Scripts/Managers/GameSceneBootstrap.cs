using UnityEngine;
using NeoOthello.Data;
using NeoOthello.UI;

namespace NeoOthello.Managers
{
    /// <summary>
    /// Bootstrap script for the Game scene.
    /// Reads the selected mode from TitleScreen and initializes GameManager.
    /// Attach this to a GameObject in the GameScene.
    /// </summary>
    public class GameSceneBootstrap : MonoBehaviour
    {
        [SerializeField] private GameManager _gameManager;

        private void Start()
        {
            if (_gameManager != null)
            {
                _gameManager.InitializeGame(TitleScreen.SelectedMode);
            }
        }
    }
}
