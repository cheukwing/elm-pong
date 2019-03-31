# elm-pong

Game of Pong made to test my understanding of the Elm architecture, as well as a refresher on web development and functional programming.

## Running

This project was made using `create-elm-app`, and so can be simply run locally via:
```
  elm-app start 
```
I am not planning on deploying this.

## Debrief

Having used React-Redux (as my first introduction to web development) last year, playing with Elm was able to better show me the MVC architecture and why it is Redux is built in such a way - something which I was not fully able to grasp at the time.
The syntax of Elm was quite easy to understand due to my prior knowledge of Haskell and my use of Elixir in the Distributed Algorithms module earlier in the year; in my opinion it has both the modernity of Elixir with the intuitivity of Haskell which made it much more fun to program in - this is of course relative to functional programming, I am not smug enough to say Haskell is more intuitive than modern imperative languages.

It was also nice to include some quick intersection calculations with inspiration from my Graphics module earlier this year, in the future I may try to refine some calculations with vector operations but I avoided them for the moment as it was not part of the core library.

The recommended style guide adds a lot of whitespace which is not particularly to my taste as the functions tend to become overly tall - but this may be more as result of my less-than-stellar method of code splitting.

While I have not played around with SVG in any capacity beforehand, the integration with Elm was very intuitive and the only painful part was the strong-typedness (not a bad thing!) of Elm forcing an abundance of `String.fromInt`, however I imagine there is a better way to do this which I am just not aware of.
