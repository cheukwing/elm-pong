module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Events as Events
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Json.Decode as D
import Set
import Svg as S
import Svg.Attributes as SA
import Time



--- CONSTANTS ---


gameWidth =
    500


gameHeight =
    500


paddleWidth =
    100


paddleHeight =
    10


initialPosition =
    gameWidth // 2 - paddleWidth // 2



---- MODEL ----


type alias Model =
    { positionOne : Int
    , positionTwo : Int
    , keysDown : Set.Set String
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


type Player
    = One
    | Two


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
        getDirection left right =
            (if Set.member left model.keysDown then
                -1

             else
                0
            )
                + (if Set.member right model.keysDown then
                    1

                   else
                    0
                  )

        dOne =
            10 * getDirection "ArrowLeft" "ArrowRight"

        dTwo =
            10 * getDirection "a" "d"

        getPosition : Int -> Int -> Int
        getPosition p d =
            min (gameWidth - paddleWidth) (max 0 (p + d))
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
                [ SA.x (String.fromInt model.positionOne)
                , SA.y (String.fromInt (gameHeight - 2 * paddleHeight))
                , SA.width (String.fromInt paddleWidth)
                , SA.height (String.fromInt paddleHeight)
                ]
                []
            , S.rect
                [ SA.x (String.fromInt model.positionTwo)
                , SA.y (String.fromInt (2 * paddleHeight))
                , SA.width (String.fromInt paddleWidth)
                , SA.height (String.fromInt paddleHeight)
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
