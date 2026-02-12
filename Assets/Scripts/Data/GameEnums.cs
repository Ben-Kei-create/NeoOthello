namespace NeoOthello.Data
{
    public enum GameMode
    {
        Classic,
        Rogue
    }

    public enum DiscType
    {
        Normal,
        Hacked,
        Bomb
    }

    public enum DiscColor
    {
        None,
        Black,
        White
    }

    public enum TurnPhase
    {
        StartTurn,
        Draw,
        SelectHand,
        Place,
        Effect,
        EndTurn
    }

    public enum PlayerType
    {
        Human,
        AI
    }
}
