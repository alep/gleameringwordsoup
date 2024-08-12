import lustre

import lustre/element
import lustre/element/html
import lustre/attribute
import gleam/dict
import grid
import gleam/io
import gleam/string
import gleam/list
import gleam/result.{unwrap}

pub type IncompleteError {
  IncompleteError(grid.Grid, List(String))
}

pub fn all_directions() -> List(grid.Direction) {
  [grid.Right, grid.Down, grid.RightDown, grid.Up, grid.Left]
}


pub fn search(gd: grid.Grid, words: List(List(String)), positions: List(Int), directions: List(grid.Direction)) -> Result(grid.Grid, IncompleteError){
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
    [_word, .._rest_words], [], [] -> 
      {
      Error(IncompleteError(gd, words |> list.map(string.concat)))
      }
    [], _, _ -> Ok(gd)
  }
} 


// The following functions are just here to document the method I tried to 
// make a full search for a possible solution
pub fn make_triplet(x: a, y: b, zs: List(c), result: List(#(a, b, c))) -> List(#(a, b, c)) {
  case zs {
    [z, ..rest_zs] -> make_triplet(x, y, rest_zs, [#(x, y, z), ..result])
    [] -> result
  }
}

pub fn combinations3(xs: List(a), ys: List(b), zs: List(c)) -> List(#(a, b, c)) {
  case xs, ys, zs {
    [x, .._rest_xs], [y, ..rest_ys], [_z, .._rest_zs] -> {
      list.append(list.flat_map(xs, fn(x) { make_triplet(x, y, zs, [])}), combinations3(xs, rest_ys, zs))
    }
    [], _, _ -> []
    _, [], _ -> []
    _, _, [] -> []
  }
}

pub fn explore(gd: grid.Grid, words: List(List(String))) -> Result(grid.Grid, #())  {
    
    case list.first(list.filter(list.map(
              list.permutations(words), 
              fn(ws) { 
                io.debug(ws) 
                list.fold(ws, Ok(gd), combine)
          }), fn(r) { case r { Ok(_) -> True Error(_) -> False}})) {
      Ok(Ok(gd)) -> Ok(gd)
      Ok(Error(_)) -> Error(#())
      Error(_) -> Error(#())
    }
}

pub fn combine(gd: Result(grid.Grid, #()), word: List(String)) -> Result(grid.Grid, #()) {
  case gd {
    Ok(gd) -> place_word(gd, word)
    Error(_t) -> Error(#())
  }
}

pub fn place_word(gd: grid.Grid, word: List(String)) -> Result(grid.Grid, #()) {
  do_place_word(gd, word, list.range(0, gd.size - 1) |> list.shuffle, all_directions() |> list.shuffle)
}

pub fn do_place_word(gd: grid.Grid, word: List(String), positions: List(Int), directions: List(grid.Direction)) -> Result(grid.Grid, #()) {
  case positions, directions { 
    [pos, .._rest_pos], [dir, ..rest_dir]  -> {
      let placement = grid.try_word(gd, word, dir, unwrap(gd |> grid.at(pos), #(0, 0)))
      case placement {
        [] -> do_place_word(gd, word, positions, rest_dir)
        [_, .._] -> Ok(gd |> grid.insert_word(placement)) 
      }
    }
    [pos, ..rest_pos], [] -> do_place_word(gd, word, rest_pos, all_directions() |> list.shuffle)
    [], _ -> Error(#())
  }
}


pub fn render(grid: grid.Grid) -> element.Element(a) {
  let rows = list.range(0, grid.size - 1) 
    |> list.map(fn(elem) { html.td([], [element.text(unwrap(dict.get(grid.data, elem), ""))]) }) 
    |> list.sized_chunk(10)
    |> list.map(fn(row) { html.tr([], row)})
  html.table([attribute.class("table")], rows)
}

pub fn not_main() {
  io.debug(combinations3([1,2], [1,2], [1,2]))
}

pub fn main() {

  let g = grid.generate(10, 10)

  let words = ["SCRATCH", "LUA", "ADA", "RUST", "ERLANG", "ELIXIR", "EFENE", "PYTHON", "OCAMML", "GLEAM", "HASKELL", "LISP", "RACKET", "SCHEME"] 
  io.debug(list.combinations(words, 13))
  let w = words |> list.map(string.to_graphemes)
  let result = case g |> search(w, list.range(0, g.size - 1), all_directions()) {
    Ok(g) -> g |> grid.fill
    Error(IncompleteError(g, ws)) -> { 
      io.println("Did my best.")
      g |> grid.fill
    }
  }

  let app = lustre.element(render(result))
  let assert Ok(_) = lustre.start(app, "#app", Nil)

   
}

