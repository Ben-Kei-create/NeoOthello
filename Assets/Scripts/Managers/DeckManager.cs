using System.Collections.Generic;
using UnityEngine;
using NeoOthello.Data;

namespace NeoOthello.Managers
{
    /// <summary>
    /// Manages the shared deck (山札). All discs start as Neutral.
    /// When drawn, they are colored based on who draws them.
    /// </summary>
    public class DeckManager
    {
        private List<DiscData> _deck = new List<DiscData>();

        public int RemainingCount => _deck.Count;
        public bool IsEmpty => _deck.Count == 0;

        /// <summary>
        /// Build the initial shared deck with the given composition.
        /// All discs are created as Neutral (colorless).
        /// </summary>
        public void BuildDeck(int normalCount = 40, int hackedCount = 8, int bombCount = 6)
        {
            _deck.Clear();

            for (int i = 0; i < normalCount; i++)
                _deck.Add(new DiscData(DiscType.Normal, DiscColor.None));

            for (int i = 0; i < hackedCount; i++)
                _deck.Add(new DiscData(DiscType.Hacked, DiscColor.None));

            for (int i = 0; i < bombCount; i++)
                _deck.Add(new DiscData(DiscType.Bomb, DiscColor.None));

            Shuffle();
        }

        /// <summary>
        /// Fisher-Yates shuffle.
        /// </summary>
        public void Shuffle()
        {
            for (int i = _deck.Count - 1; i > 0; i--)
            {
                int j = Random.Range(0, i + 1);
                (_deck[i], _deck[j]) = (_deck[j], _deck[i]);
            }
        }

        /// <summary>
        /// Draw one disc from the top and color it for the drawing player.
        /// Returns null if deck is empty.
        /// </summary>
        public DiscData Draw(DiscColor playerColor)
        {
            if (_deck.Count == 0) return null;

            DiscData disc = _deck[0];
            _deck.RemoveAt(0);

            // Dye the disc to the player's color upon draw
            disc.Color = playerColor;

            return disc;
        }

        /// <summary>
        /// Peek at the top disc without removing it.
        /// </summary>
        public DiscData Peek()
        {
            return _deck.Count > 0 ? _deck[0] : null;
        }
    }
}
