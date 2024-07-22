import grid
import gleam/io
import gleam/string
import gleam/list
import gleam/result.{unwrap}

pub type IncompleteError {
  IncompleteError(grid.Grid, List(String))
}

pub fn all_directions() -> List(grid.Direction) {
  [grid.Right, grid.Down, grid.RightDown]
}


pub fn search(gd: grid.Grid, words:List(List(String)), positions: List(Int), directions: List(grid.Direction)) -> Result(grid.Grid, IncompleteError){
  case words, positions, directions {
    [word, ..rest_words], [pos, .._rest_positions], [dir, ..rest_directions] -> {
      let placement = grid.try_word(gd, word, dir, unwrap(gd |> grid.at(pos), #(0, 0)))
      let #(next_gd, next_words) = case placement {
        [] -> #(gd, words)
        [_, .._] -> #(gd |> grid.insert_word(placement), rest_words) 
      }
      search(next_gd, next_words, positions, rest_directions |> list.shuffle)
    }
    [_word, .._rest_words], [_pos, ..rest_positions], [] -> {
      search(gd, words, rest_positions |> list.shuffle, all_directions() |> list.shuffle)
    }
    [_word, .._rest_words], [], [_, ..]  -> Error(IncompleteError(gd, words |> list.map(string.concat)))
    [_word, .._rest_words], [], [] -> Error(IncompleteError(gd, words |> list.map(string.concat)))
    [], _, _ -> Ok(gd)
  }
} 



pub fn main() {
  let g = grid.generate(10, 10)
  let words = ["SCRATCH", "LUA", "ADA", "RUST", "ERLANG", "ELIXIR", "EFENE", "PYTHON", "OCAMML", "GLEAM", "HASKELL", "LISP", "RACKET", "SCHEME"] |> list.map(string.to_graphemes)
  case g |> search(words, list.range(0, g.size) |> list.shuffle, all_directions() |> list.shuffle) {
    Ok(g) -> g |> grid.fill  |> grid.print
    Error(IncompleteError(g, words)) -> { 
      io.println("Did my best. Missing words: " <> string.join(words, ","))
      g |> grid.print
    }
  }
}

