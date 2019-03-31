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


ballRadius =
    5


ballSpeed =
    4


ballReflectAngle =
    60


initialBallPosition =
    ( gameWidth / 2, gameHeight / 2 )


initialPosition =
    gameHeight / 2 - paddleHeight / 2


paddleLeft =
    paddleWidth


paddleRight =
    gameWidth - 2 * paddleWidth


paddleSpeed =
    8



---- MODEL ----


type alias Model =
    { positionLeft : Float
    , positionRight : Float
    , positionBall : ( Float, Float )
    , directionBall : ( Float, Float )
    , keysDown : Set String
    }


init : ( Model, Cmd Msg )
init =
    ( { positionLeft = initialPosition
      , positionRight = initialPosition
      , positionBall = initialBallPosition
      , directionBall = ( 1, 0 )
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
            getPaddlePositions model

        nextBallDirection =
            getBallDirection model
    in
    case msg of
        KeyUp k ->
            ( { model | keysDown = Set.remove k model.keysDown }, Cmd.none )

        KeyDown k ->
            ( { model | keysDown = Set.insert k model.keysDown }, Cmd.none )

        Render _ ->
            case nextBallDirection of
                Just direction ->
                    ( { model
                        | positionLeft = pOne
                        , positionRight = pTwo
                        , positionBall = getBallPosition model.positionBall direction
                        , directionBall = direction
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model
                        | positionLeft = pOne
                        , positionRight = pTwo
                        , positionBall = initialBallPosition
                        , directionBall = ( 1, 0 )
                      }
                    , Cmd.none
                    )


type Object
    = PaddleLeft
    | PaddleRight
    | WallNorth
    | WallEast
    | WallSouth
    | WallWest


getIntersection : Model -> Maybe Object
getIntersection model =
    let
        ( bx, by ) =
            model.positionBall

        ( pw, ph ) =
            ( paddleWidth, paddleHeight )

        r =
            ballRadius

        intersectsBall : ( Float, Float ) -> Bool
        intersectsBall ( x, y ) =
            not (x > bx + r || x + pw < bx - r || y > by + r || y + ph < by - r)

        intersectionChecks =
            [ ( intersectsBall ( paddleLeft, model.positionLeft ), PaddleLeft )
            , ( intersectsBall ( paddleRight, model.positionRight ), PaddleRight )
            , ( by - r <= 0, WallNorth )
            , ( by + r >= gameHeight, WallSouth )
            , ( bx - r <= 0, WallWest )
            , ( bx + r >= gameWidth, WallEast )
            ]

        intersection =
            intersectionChecks |> List.filter Tuple.first |> List.map Tuple.second
    in
    List.head intersection


getBallDirection : Model -> Maybe ( Float, Float )
getBallDirection model =
    let
        intersection =
            getIntersection model

        ( dx, dy ) =
            model.directionBall

        ( _, by ) =
            model.positionBall

        ( y1, y2 ) =
            ( model.positionLeft, model.positionRight )

        paddleSpan =
            paddleHeight / 2

        relativeLeft =
            ((y1 + paddleSpan) - by) / paddleSpan

        relativeRight =
            ((y2 + paddleSpan) - by) / paddleSpan

        xReflect relative =
            cos (degrees (relative * ballReflectAngle))

        yReflect relative =
            sin (degrees (relative * ballReflectAngle))
    in
    case intersection of
        Just WallNorth ->
            Just ( dx, -dy )

        Just WallSouth ->
            Just ( dx, -dy )

        Just WallEast ->
            Nothing

        Just WallWest ->
            Nothing

        Just PaddleLeft ->
            Just ( xReflect relativeLeft, negate <| yReflect relativeLeft )

        Just PaddleRight ->
            Just ( negate <| xReflect relativeRight, negate <| yReflect relativeRight )

        Nothing ->
            Just model.directionBall


getBallPosition : ( Float, Float ) -> ( Float, Float ) -> ( Float, Float )
getBallPosition ( px, py ) ( dx, dy ) =
    let
        nx =
            min gameWidth (max 0 (px + ballSpeed * dx))

        ny =
            min gameHeight (max 0 (py + ballSpeed * dy))
    in
    ( nx, ny )


getPaddlePositions : Model -> ( Float, Float )
getPaddlePositions model =
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

        getPosition : Float -> Int -> Float
        getPosition p d =
            min (gameHeight - paddleHeight) (max 0 (p + toFloat d))
    in
    ( getPosition model.positionLeft dOne, getPosition model.positionRight dTwo )



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
    let
        ( bx, by ) =
            model.positionBall

        pw =
            String.fromInt paddleWidth

        ph =
            String.fromInt paddleHeight
    in
    div []
        [ h1 [] [ text "Elm Pong" ]
        , S.svg
            [ SA.width (String.fromInt gameWidth)
            , SA.height (String.fromInt gameHeight)
            , SA.viewBox ("0 0 " ++ String.fromInt gameWidth ++ " " ++ String.fromInt gameHeight)
            ]
            [ S.rect
                [ SA.x (String.fromInt paddleLeft)
                , SA.y (String.fromFloat model.positionLeft)
                , SA.width pw
                , SA.height ph
                ]
                []
            , S.rect
                [ SA.x (String.fromInt paddleRight)
                , SA.y (String.fromFloat model.positionRight)
                , SA.width pw
                , SA.height ph
                ]
                []
            , S.circle
                [ SA.cx (String.fromFloat bx)
                , SA.cy (String.fromFloat by)
                , SA.r (String.fromInt ballRadius)
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
