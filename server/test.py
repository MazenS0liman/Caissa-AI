from neurosymbolicAI import NeuroSymbolic

ns = NeuroSymbolic()
ns.symbolic.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
ns.symbolic.display_board_cli()
print("\n")
ns.symbolic.make_move(
    piece='pawn',
    color='white',
    from_position='h2',
    to_position='h3',
)
ns.symbolic.display_board_cli()
