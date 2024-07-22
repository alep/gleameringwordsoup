import grid
import gleam/dict
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn grid_get_test() {
  let g = grid.generate(5, 5)
  grid.index(g, 2, 2) |> should.equal("-")
}

pub fn at_test() {
  let g = grid.generate(5, 5)
  grid.at(g, 26) |> should.equal(Error(grid.GridIndexError(26)))
}


pub fn neighbors_empty_test() {
  grid.try_word(grid.generate(0, 0), ["S", "t", "u"], grid.Right, #(0, 0)) |> should.equal([])
}

pub fn neighbors_stu_test() {
  let g = grid.generate(5, 5)
  g.data 
    |> dict.insert(0, "S")
    |> dict.insert(5, "t")
    |> dict.insert(10, "u")
  grid.try_word(g, ["S", "t", "u"], grid.Right, #(0, 0)) |> should.equal([#(#(0, 2), "u"), #(#(0, 1), "t"), #(#(0, 0), "S")])

}


// pub fn neighbors_right_test() {
//   grid.neighbors(grid.Right, #(0, 0), #(5, 5)) |> should.equal([#(0, 1), #(0, 2), #(0, 3), #(0, 4)])
//}
