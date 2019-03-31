module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Events as Events
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (src)
import Json.Decode as D
import Set exposing (Set)
import Svg as S
import Svg.Attributes as SA
import Time



--- CONSTANTS ---


gameWidth =
    500


gameHeight =
    500


paddleWidth =
    10


paddleHeight =
    100


initialPosition =
    gameWidth // 2 - paddleWidth // 2



---- MODEL ----


type alias Model =
    { positionOne : Int
    , positionTwo : Int
    , keysDown : Set String
    }


init : ( Model, Cmd Msg )
init =
    ( { positionOne = initialPosition
      , positionTwo = initialPosition
      , keysDown = Set.empty
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = KeyUp String
    | KeyDown String
    | Render Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( pOne, pTwo ) =
            getNewPositions model
    in
    case msg of
        KeyUp k ->
            ( { model | keysDown = Set.remove k model.keysDown }, Cmd.none )

        KeyDown k ->
            ( { model | keysDown = Set.insert k model.keysDown }, Cmd.none )

        Render _ ->
            ( { model | positionOne = pOne, positionTwo = pTwo }, Cmd.none )


getNewPositions : Model -> ( Int, Int )
getNewPositions model =
    let
        getDirection : String -> String -> Int
        getDirection up down =
            (if Set.member up model.keysDown then
                -1

             else
                0
            )
                + (if Set.member down model.keysDown then
                    1

                   else
                    0
                  )

        dOne =
            10 * getDirection "w" "s"

        dTwo =
            10 * getDirection "ArrowUp" "ArrowDown"

        getPosition : Int -> Int -> Int
        getPosition p d =
            min (gameHeight - paddleHeight) (max 0 (p + d))
    in
    ( getPosition model.positionOne dOne, getPosition model.positionTwo dTwo )



--- SUBSCRIPTIONS ---


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Events.onKeyDown (D.map KeyDown keyDecoder)
        , Events.onKeyUp (D.map KeyUp keyDecoder)
        , Events.onAnimationFrame Render
        ]


keyDecoder : D.Decoder String
keyDecoder =
    D.field "key" D.string



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Elm Pong" ]
        , S.svg
            [ SA.width (String.fromInt gameWidth)
            , SA.height (String.fromInt gameHeight)
            , SA.viewBox ("0 0 " ++ String.fromInt gameWidth ++ " " ++ String.fromInt gameHeight)
            ]
            [ S.rect
                [ SA.x (String.fromInt (2 * paddleWidth))
                , SA.y (String.fromInt model.positionOne)
                , SA.width (String.fromInt paddleWidth)
                , SA.height (String.fromInt paddleHeight)
                ]
                []
            , S.rect
                [ SA.x (String.fromInt (gameWidth - 2 * paddleWidth))
                , SA.y (String.fromInt model.positionTwo)
                , SA.width (String.fromInt paddleWidth)
                , SA.height (String.fromInt paddleHeight)
                ]
                []
            , S.circle
                [ SA.cx (String.fromInt (gameWidth // 2))
                , SA.cy (String.fromInt (gameHeight // 2))
                , SA.r "5"
                ]
                []
            ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
