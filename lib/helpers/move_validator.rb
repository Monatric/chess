# frozen_string_literal: true

module Chess
  # This class helps validating a player's move which consists a lot of factors such as
  # format and moveability.
  class MoveValidator
    def initialize(source:, dest:, game: Game.new)
      @game = game
      @chessboard = game.chessboard
      @source = source
      @dest = dest
    end

    def valid_move?
      return false if castling_attempt? && !valid_castling?

      valid_format? && valid_positions? &&
        piece_belongs_to_current_player? && piece_can_move_to? &&
        ThreatAnalyzer.move_avoids_check?(@source, @dest, @game)
    end

    def move_is_castling?(source, dest)
      %w[e1g1 e1c1 e8g8 e8c8].include?(source.to_s + dest.to_s)
    end

    def move_is_promotion?(piece, dest)
      piece.is_a?(Pawn) && PawnPromotion.promotion_square?(piece, dest)
    end

    def valid_format?
      (@source.to_s + @dest.to_s).length == 4
    end

    def valid_positions?
      @game.chessboard.valid_source_and_dest?(@source, @dest)
    end

    def castling_attempt?
      %i[e1g1 e1c1 e8g8 e8c8].include?("#{@source}#{@dest}".to_sym)
    end

    def valid_castling?
      dest_to_rook_coord = { c1: :a1, g1: :h1, c8: :a8, g8: :h8 }
      rook_coord = dest_to_rook_coord[@dest]
      castling_first_square = { c1: :d1, g1: :f1 }
      first_square_before_castling = castling_first_square[@dest]
      check_result = ThreatAnalyzer.move_avoids_check?(@source, first_square_before_castling, @game)

      king = @chessboard.find_piece_by_coordinate(@source)
      rook = @chessboard.find_piece_by_coordinate(rook_coord)
      king.castleable? && rook&.castleable? && check_result
    end

    def piece_belongs_to_current_player?
      piece = @chessboard.find_piece_by_coordinate(@source)
      piece && piece.color == @game.current_turn_color
    end

    def piece_can_move_to?
      piece = @chessboard.find_piece_by_coordinate(@source)
      piece && piece.can_move_to?(@dest, @chessboard)
    end
  end
end
