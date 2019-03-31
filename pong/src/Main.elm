module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Events as Events
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Json.Decode as D
import Svg as S
import Svg.Attributes as SA



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
    }


init : ( Model, Cmd Msg )
init =
    ( { positionOne = initialPosition
      , positionTwo = initialPosition
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = Left Player
    | Right Player
    | None


type Player
    = One
    | Two


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Left One ->
            ( { model
                | positionOne = max 0 (model.positionOne - 10)
              }
            , Cmd.none
            )

        Left Two ->
            ( { model
                | positionTwo = max 0 (model.positionTwo - 10)
              }
            , Cmd.none
            )

        Right One ->
            ( { model
                | positionOne = min (gameWidth - paddleWidth) (model.positionOne + 10)
              }
            , Cmd.none
            )

        Right Two ->
            ( { model
                | positionTwo = min (gameWidth - paddleWidth) (model.positionTwo + 10)
              }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )



--- SUBSCRIPTIONS ---


subscriptions : Model -> Sub Msg
subscriptions model =
    Events.onKeyDown keyDecoder


keyDecoder : D.Decoder Msg
keyDecoder =
    D.map toDirection (D.field "key" D.string)


toDirection : String -> Msg
toDirection s =
    case s of
        "ArrowLeft" ->
            Left One

        "ArrowRight" ->
            Right One

        "a" ->
            Left Two

        "d" ->
            Right Two

        _ ->
            None



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
