using UnityEngine;
using UnityEngine.UI;
using NeoOthello.Data;
using NeoOthello.Managers;

namespace NeoOthello.UI
{
    /// <summary>
    /// Displays the player's hand slots using Unity UI.
    /// Dynamically adjusts slot count based on hand capacity.
    /// </summary>
    public class HandUI : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Transform _slotContainer;
        [SerializeField] private GameObject _slotPrefab;

        [Header("Colors")]
        [SerializeField] private Color _normalColor = Color.gray;
        [SerializeField] private Color _hackedColor = new Color(0.8f, 0.2f, 0.2f);
        [SerializeField] private Color _bombColor = new Color(1f, 0.5f, 0f);
        [SerializeField] private Color _emptySlotColor = new Color(0.3f, 0.3f, 0.3f, 0.5f);
        [SerializeField] private Color _lockedSlotColor = new Color(0.15f, 0.15f, 0.15f, 0.3f);
        [SerializeField] private Color _selectedColor = Color.yellow;

        private HandManager _handManager;
        private TurnManager _turnManager;
        private GameObject[] _slots;
        private int _selectedIndex = -1;

        public void Initialize(HandManager handManager, TurnManager turnManager)
        {
            _handManager = handManager;
            _turnManager = turnManager;

            _handManager.OnHandChanged += RefreshSlots;
            _handManager.OnHandCapacityChanged += OnCapacityChanged;

            BuildSlots();
            RefreshSlots();
        }

        private void BuildSlots()
        {
            // Clear existing
            if (_slots != null)
            {
                foreach (var slot in _slots)
                    if (slot != null) Destroy(slot);
            }

            // Build max possible slots
            _slots = new GameObject[HandManager.MaxHandCapacity];

            for (int i = 0; i < HandManager.MaxHandCapacity; i++)
            {
                GameObject slot;
                if (_slotPrefab != null)
                {
                    slot = Instantiate(_slotPrefab, _slotContainer);
                }
                else
                {
                    slot = CreateDefaultSlot(_slotContainer);
                }

                slot.name = $"Slot_{i}";

                int index = i; // Capture for closure
                var button = slot.GetComponent<Button>();
                if (button != null)
                {
                    button.onClick.AddListener(() => OnSlotClicked(index));
                }

                _slots[i] = slot;
            }
        }

        private GameObject CreateDefaultSlot(Transform parent)
        {
            var slotObj = new GameObject("Slot", typeof(RectTransform), typeof(Image), typeof(Button));
            slotObj.transform.SetParent(parent, false);

            var rect = slotObj.GetComponent<RectTransform>();
            rect.sizeDelta = new Vector2(80, 100);

            var image = slotObj.GetComponent<Image>();
            image.color = _emptySlotColor;

            // Label for disc type
            var labelObj = new GameObject("Label", typeof(RectTransform), typeof(Text));
            labelObj.transform.SetParent(slotObj.transform, false);

            var labelRect = labelObj.GetComponent<RectTransform>();
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;

            var text = labelObj.GetComponent<Text>();
            text.alignment = TextAnchor.MiddleCenter;
            text.fontSize = 14;
            text.color = Color.white;
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            return slotObj;
        }

        public void RefreshSlots()
        {
            if (_handManager == null || _slots == null) return;

            for (int i = 0; i < HandManager.MaxHandCapacity; i++)
            {
                if (_slots[i] == null) continue;

                var image = _slots[i].GetComponent<Image>();
                var label = _slots[i].GetComponentInChildren<Text>();
                var button = _slots[i].GetComponent<Button>();

                if (i >= _handManager.HandCapacity)
                {
                    // Locked slot
                    _slots[i].SetActive(true);
                    if (image != null) image.color = _lockedSlotColor;
                    if (label != null) label.text = "Locked";
                    if (button != null) button.interactable = false;
                }
                else if (i < _handManager.CurrentCount)
                {
                    // Has a disc
                    _slots[i].SetActive(true);
                    var disc = _handManager.GetDisc(i);

                    Color slotColor = disc.Type switch
                    {
                        DiscType.Normal => _normalColor,
                        DiscType.Hacked => _hackedColor,
                        DiscType.Bomb => _bombColor,
                        _ => _normalColor
                    };

                    if (i == _selectedIndex)
                        slotColor = _selectedColor;

                    if (image != null) image.color = slotColor;
                    if (label != null) label.text = disc.Type.ToString();
                    if (button != null) button.interactable = true;
                }
                else
                {
                    // Empty but unlocked slot
                    _slots[i].SetActive(true);
                    if (image != null) image.color = _emptySlotColor;
                    if (label != null) label.text = "";
                    if (button != null) button.interactable = false;
                }
            }
        }

        private void OnSlotClicked(int index)
        {
            if (_turnManager == null) return;
            if (_turnManager.CurrentPhase != TurnPhase.SelectHand) return;
            if (index >= _handManager.CurrentCount) return;

            _selectedIndex = -1; // Reset after selection
            _turnManager.OnPlayerSelectHandDisc(index);
            RefreshSlots();
        }

        private void OnCapacityChanged(int newCapacity)
        {
            RefreshSlots();
        }

        private void OnDestroy()
        {
            if (_handManager != null)
            {
                _handManager.OnHandChanged -= RefreshSlots;
                _handManager.OnHandCapacityChanged -= OnCapacityChanged;
            }
        }
    }
}
