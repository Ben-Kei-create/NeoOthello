using System;
using System.Collections.Generic;
using NeoOthello.Data;

namespace NeoOthello.Managers
{
    /// <summary>
    /// Manages a player's hand. Supports dynamic hand capacity (Limit Break).
    /// </summary>
    public class HandManager
    {
        public const int InitialHandCapacity = 3;
        public const int MaxHandCapacity = 5;
        public const int LimitBreakThreshold = 6; // Flip 6+ to trigger

        private List<DiscData> _hand = new List<DiscData>();
        private int _handCapacity;
        private DiscColor _ownerColor;

        public IReadOnlyList<DiscData> Hand => _hand;
        public int HandCapacity => _handCapacity;
        public int CurrentCount => _hand.Count;
        public bool IsFull => _hand.Count >= _handCapacity;
        public int SlotsAvailable => _handCapacity - _hand.Count;
        public DiscColor OwnerColor => _ownerColor;

        public event Action<int> OnHandCapacityChanged;
        public event Action OnHandChanged;

        public HandManager(DiscColor ownerColor)
        {
            _ownerColor = ownerColor;
            _handCapacity = InitialHandCapacity;
        }

        public void AddToHand(DiscData disc)
        {
            if (_hand.Count >= _handCapacity) return;
            _hand.Add(disc);
            OnHandChanged?.Invoke();
        }

        public DiscData RemoveFromHand(int index)
        {
            if (index < 0 || index >= _hand.Count) return null;
            DiscData disc = _hand[index];
            _hand.RemoveAt(index);
            OnHandChanged?.Invoke();
            return disc;
        }

        /// <summary>
        /// Attempt to expand hand capacity (Limit Break / Kaihou).
        /// Returns true if capacity was actually increased.
        /// </summary>
        public bool TryExpandCapacity()
        {
            if (_handCapacity >= MaxHandCapacity) return false;
            _handCapacity++;
            OnHandCapacityChanged?.Invoke(_handCapacity);
            return true;
        }

        /// <summary>
        /// Check if a flip count triggers Limit Break.
        /// </summary>
        public bool CheckLimitBreak(int flippedCount)
        {
            return flippedCount >= LimitBreakThreshold;
        }

        public void Clear()
        {
            _hand.Clear();
            _handCapacity = InitialHandCapacity;
            OnHandChanged?.Invoke();
        }

        public DiscData GetDisc(int index)
        {
            if (index < 0 || index >= _hand.Count) return null;
            return _hand[index];
        }
    }
}
