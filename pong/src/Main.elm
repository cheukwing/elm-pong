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
    , scoreLeft : Int
    , scoreRight : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { positionLeft = initialPosition
      , positionRight = initialPosition
      , positionBall = initialBallPosition
      , directionBall = ( 1, 0 )
      , keysDown = Set.empty
      , scoreLeft = 0
      , scoreRight = 0
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = KeyUp String
    | KeyDown String
    | UpdateState Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( pOne, pTwo ) =
            getPaddlePositions model
    in
    case msg of
        KeyUp k ->
            ( { model | keysDown = Set.remove k model.keysDown }, Cmd.none )

        KeyDown k ->
            ( { model | keysDown = Set.insert k model.keysDown }, Cmd.none )

        UpdateState _ ->
            updateState model


updateState : Model -> ( Model, Cmd Msg )
updateState model =
    let
        pb =
            model.positionBall

        (( dx, dy ) as db) =
            model.directionBall

        ( pLeft, pRight ) =
            getPaddlePositions model

        initial =
            { model
                | positionLeft = initialPosition
                , positionRight = initialPosition
                , positionBall = initialBallPosition
            }

        movedPaddles =
            { model | positionLeft = pLeft, positionRight = pRight }

        intersection =
            getIntersection model

        rd =
            getReflection model intersection
    in
    case intersection of
        ReachLeft ->
            ( { initial
                | directionBall = ( -1, 0 )
                , scoreRight = model.scoreRight + 1
              }
            , Cmd.none
            )

        ReachRight ->
            ( { initial
                | directionBall = ( 1, 0 )
                , scoreLeft = model.scoreLeft + 1
              }
            , Cmd.none
            )

        Boundary ->
            ( { movedPaddles
                | positionBall = getBallPosition pb ( dx, -dy )
                , directionBall = ( dx, -dy )
              }
            , Cmd.none
            )

        None ->
            ( { movedPaddles | positionBall = getBallPosition pb db }
            , Cmd.none
            )

        _ ->
            ( { movedPaddles
                | positionBall = getBallPosition pb rd
                , directionBall = rd
              }
            , Cmd.none
            )


type IntersectionResult
    = Boundary
    | PongLeft
    | PongRight
    | ReachLeft
    | ReachRight
    | None


getIntersection : Model -> IntersectionResult
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
            [ ( intersectsBall ( paddleLeft, model.positionLeft ), PongLeft )
            , ( intersectsBall ( paddleRight, model.positionRight ), PongRight )
            , ( by - r <= 0, Boundary )
            , ( by + r >= gameHeight, Boundary )
            , ( bx - r <= 0, ReachLeft )
            , ( bx + r >= gameWidth, ReachRight )
            ]

        intersection =
            intersectionChecks |> List.filter Tuple.first |> List.map Tuple.second
    in
    case List.head intersection of
        Just result ->
            result

        Nothing ->
            None


getReflection : Model -> IntersectionResult -> ( Float, Float )
getReflection model intersection =
    let
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
        PongLeft ->
            ( xReflect relativeLeft, negate <| yReflect relativeLeft )

        PongRight ->
            ( negate <| xReflect relativeRight, negate <| yReflect relativeRight )

        _ ->
            model.directionBall


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
            paddleSpeed * getDirection "w" "s"

        dTwo =
            paddleSpeed * getDirection "ArrowUp" "ArrowDown"

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
        , Events.onAnimationFrame UpdateState
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
            , S.text_
                [ SA.x (String.fromInt (gameWidth // 2 - 100))
                , SA.y "100"
                , SA.fontSize "50px"
                ]
                [ S.text (String.fromInt model.scoreLeft) ]
            , S.text_
                [ SA.x (String.fromInt (gameWidth // 2 + 100))
                , SA.y "100"
                , SA.fontSize "50px"
                ]
                [ S.text (String.fromInt model.scoreRight) ]
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
