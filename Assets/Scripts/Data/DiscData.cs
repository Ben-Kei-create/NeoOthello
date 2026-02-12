using System;

namespace NeoOthello.Data
{
    [Serializable]
    public class DiscData
    {
        public DiscType Type;
        public DiscColor Color;

        public DiscData(DiscType type, DiscColor color = DiscColor.None)
        {
            Type = type;
            Color = color;
        }

        public DiscData Clone()
        {
            return new DiscData(Type, Color);
        }

        public override string ToString()
        {
            return $"[{Color} {Type}]";
        }
    }
}
