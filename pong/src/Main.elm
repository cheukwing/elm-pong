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



---- MODEL ----


type alias Model =
    { position : Int }


init : ( Model, Cmd Msg )
init =
    ( { position = 0 }, Cmd.none )



---- UPDATE ----


type Msg
    = Move Direction


type Direction
    = Left
    | Right
    | None


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Move Left ->
            ( { model | position = max 0 (model.position - 10) }, Cmd.none )

        Move Right ->
            ( { model | position = min (gameWidth - paddleWidth) (model.position + 10) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



--- SUBSCRIPTIONS ---


subscriptions : Model -> Sub Msg
subscriptions model =
    Events.onKeyDown (D.map Move keyDecoder)


keyDecoder : D.Decoder Direction
keyDecoder =
    D.map toDirection (D.field "key" D.string)


toDirection : String -> Direction
toDirection s =
    case s of
        "ArrowLeft" ->
            Left

        "ArrowRight" ->
            Right

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
                [ SA.x (String.fromInt model.position)
                , SA.y (String.fromInt (gameHeight - 2 * paddleHeight))
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
