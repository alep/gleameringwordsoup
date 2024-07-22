import gleam/io
import gleam/dict.{type Dict}
import gleam/int.{to_string}
import gleam/list
import gleam/string 
import gleam/result.{unwrap}

pub type Grid {
  Grid(data: Dict(Int, String), nrows: Int, ncols: Int, size: Int)
}

pub type GridError {
  GridIndexError(position: Int)
}

pub fn generate(nrows: Int, ncols: Int) -> Grid {
  let size = nrows * ncols
  Grid(
    data: dict.from_list(list.zip(list.range(0, size - 1), list.repeat("-", size))), 
    nrows: nrows,
    ncols: ncols,
    size: size)
}

pub fn index(grid: Grid, row: Int, col: Int) -> String {
  let index = row * grid.ncols + col
  unwrap(dict.get(grid.data, index), "")
}

pub fn insert(grid: Grid, row: Int, col: Int, val: String) -> Grid {
  let index = row * grid.ncols + col
  let grid : Grid = Grid(data: grid.data |> dict.insert(index, val), nrows: grid.nrows, ncols: grid.ncols, size: grid.size)
  grid
}

pub fn at(grid: Grid, position: Int) -> Result(#(Int, Int), GridError) {
  case position > grid.size {
    True -> Error(GridIndexError(position))
    False -> { 
      let row = position / grid.ncols
      let col = position % grid.ncols
      Ok(#(row, col))
    }
  }
}

const chars = "ABCDEFGHIJLMNOPQRSTUVXYZ"

pub fn fill(grid: Grid) -> Grid {
  let d = dict.map_values(grid.data, fn(k, v) {
    case v {
      "-" -> chars |> string.to_graphemes
                   |> list.shuffle
                   |> list.first
                   |> unwrap("-")
      _ -> v
    }
  })
  Grid(data: d, nrows: grid.nrows, ncols: grid.ncols, size: grid.size)
  
}


pub fn print(grid: Grid) {
  list.each(list.range(0, grid.size - 1), fn(elem) {
    case {elem % grid.ncols == 0} && {elem != 0} {
      True -> io.print("\n" <> unwrap(dict.get(grid.data, elem), "") <> " ")
      False -> {
      let s = case elem { 
        0 -> "" 
        _ -> " "
      }
      io.print(s <> unwrap(dict.get(grid.data, elem), "") <> " ")
      }
    }
  })
}


pub type Direction {
    Right
    Left
    Up
    Down
    RightDown
    RightUp
    LeftDown
    LeftUp
}

pub fn to_tuple(dir: Direction) -> #(Int, Int) {
  case dir {
    Right -> #(0, 1)
    Left -> #(0, -1)
    Up -> #(-1, 0)
    Down -> #(1, 0)
    RightDown -> #(1, 1)
    RightUp -> #(-1, 1)
    LeftDown -> #(1, -1)
    LeftUp -> #(-1, -1)
  }
}


pub fn try_word(grid: Grid, word: List(String), dir: Direction, position: #(Int, Int)) -> List(#(#(Int, Int), String)) {
  let delta = to_tuple(dir)
  let limits = #(grid.nrows, grid.ncols)
  case try_word_loop(grid, delta, position, word, limits, []) {
    Ok(list) -> list
    Error(_) -> []
  }
}

fn try_word_loop(grid: Grid, dir: #(Int, Int), position: #(Int, Int), 
  word: List(String), limits: #(Int, Int), acc: List(#(#(Int, Int), String))) -> Result(List(#(#(Int, Int), String)), GridError) {
  case word {
    [] -> Ok(acc)
    [char ..rest] -> {
      let #(row, col) = position
      let #(nrows, ncols) = limits
      case {0 <= row && row < nrows } && {0 <= col && col < ncols} {
        True -> {
          let value = index(grid, row, col)
          case { value == "-" || value == char } {
            True -> {
              let #(delta_x, delta_y) = dir
              let next = #(row + delta_x, col + delta_y)
              try_word_loop(grid, dir, next, rest, limits, [#(position, char) ..acc])
            }
            False -> {
              Error(GridIndexError(-1)) 
            }
          }
        }
        False -> Error(GridIndexError(-1)) 
      }
    }
  }
}

pub fn insert_word(grid: Grid, word: List(#(#(Int, Int), String))) -> Grid {
  word |> list.fold(grid,
    fn(grid, t) -> Grid {
      let #(#(r, c), val) = t
      grid |> insert(r, c, val)
    })
}


