module Commands.Generate exposing (run)

import CodeGen
import CodeGen.Annotation
import CodeGen.Argument
import CodeGen.Declaration
import CodeGen.Expression
import CodeGen.Import
import CodeGen.Module
import Filepath exposing (Filepath)
import Json.Decode
import PageFile exposing (PageFile)


run : Json.Decode.Value -> List CodeGen.Module
run json =
    case Json.Decode.decodeValue decoder json of
        Ok data ->
            List.concat
                [ [ mainElmModule data
                  , routeElmModule data
                  , notFoundModule
                  ]
                , if List.isEmpty data.layouts then
                    []

                  else
                    [ elmLandLayoutsElmModule data ]
                ]

        Err _ ->
            []


mainElmModule : Data -> CodeGen.Module
mainElmModule data =
    CodeGen.Module.new
        { name = [ "Main" ]
        , exposing_ = [ "main" ]
        , imports =
            List.concat
                [ [ CodeGen.Import.new [ "Browser" ]
                  , CodeGen.Import.new [ "Browser", "Navigation" ]
                  , CodeGen.Import.new [ "Html" ]
                        |> CodeGen.Import.withExposing [ "Html" ]
                  , CodeGen.Import.new [ "Json", "Decode" ]
                  ]
                , data.layouts
                    |> List.map Filepath.toList
                    |> List.map (\pieces -> "Layouts" :: pieces)
                    |> List.map CodeGen.Import.new
                , data.pages
                    |> List.map PageFile.toFilepath
                    |> List.map Filepath.toList
                    |> List.map (\pieces -> "Pages" :: pieces)
                    |> List.map CodeGen.Import.new
                , [ CodeGen.Import.new [ "Pages", "NotFound_" ]
                  , CodeGen.Import.new [ "Route" ]
                  , CodeGen.Import.new [ "Url" ]
                        |> CodeGen.Import.withExposing [ "Url" ]
                  ]
                ]
        , declarations =
            [ CodeGen.Declaration.typeAlias
                { name = "Flags"
                , annotation = CodeGen.Annotation.type_ "Json.Decode.Value"
                }
            , CodeGen.Declaration.function
                { name = "main"
                , annotation = CodeGen.Annotation.type_ "Program Flags Model Msg"
                , arguments = []
                , expression =
                    CodeGen.Expression.multilineFunction
                        { name = "Browser.application"
                        , arguments =
                            [ CodeGen.Expression.multilineRecord
                                [ ( "init", CodeGen.Expression.value "init" )
                                , ( "update", CodeGen.Expression.value "update" )
                                , ( "view", CodeGen.Expression.value "view" )
                                , ( "subscriptions", CodeGen.Expression.value "subscriptions" )
                                , ( "onUrlChange", CodeGen.Expression.value "UrlChanged" )
                                , ( "onUrlRequest", CodeGen.Expression.value "UrlRequested" )
                                ]
                            ]
                        }
                }
            , CodeGen.Declaration.comment [ "INIT" ]
            , CodeGen.Declaration.typeAlias
                { name = "Model"
                , annotation =
                    CodeGen.Annotation.multilineRecord
                        [ ( "flags", CodeGen.Annotation.type_ "Flags" )
                        , ( "key", CodeGen.Annotation.type_ "Browser.Navigation.Key" )
                        , ( "url", CodeGen.Annotation.type_ "Url" )
                        ]
                }
            , CodeGen.Declaration.function
                { name = "init"
                , annotation =
                    CodeGen.Annotation.function
                        [ CodeGen.Annotation.type_ "Flags"
                        , CodeGen.Annotation.type_ "Url"
                        , CodeGen.Annotation.type_ "Browser.Navigation.Key"
                        , CodeGen.Annotation.type_ "( Model, Cmd Msg )"
                        ]
                , arguments =
                    [ CodeGen.Argument.new "flags"
                    , CodeGen.Argument.new "url"
                    , CodeGen.Argument.new "key"
                    ]
                , expression =
                    CodeGen.Expression.multilineTuple
                        [ CodeGen.Expression.multilineRecord
                            [ ( "flags", CodeGen.Expression.value "flags" )
                            , ( "url", CodeGen.Expression.value "url" )
                            , ( "key", CodeGen.Expression.value "key" )
                            ]
                        , CodeGen.Expression.value "Cmd.none"
                        ]
                }
            , CodeGen.Declaration.comment [ "UPDATE" ]
            , CodeGen.Declaration.customType
                { name = "Msg"
                , variants =
                    [ ( "UrlRequested", [ CodeGen.Annotation.type_ "Browser.UrlRequest" ] )
                    , ( "UrlChanged", [ CodeGen.Annotation.type_ "Url" ] )
                    ]
                }
            , CodeGen.Declaration.function
                { name = "update"
                , annotation =
                    CodeGen.Annotation.function
                        [ CodeGen.Annotation.type_ "Msg"
                        , CodeGen.Annotation.type_ "Model"
                        , CodeGen.Annotation.type_ "( Model, Cmd Msg )"
                        ]
                , arguments =
                    [ CodeGen.Argument.new "msg"
                    , CodeGen.Argument.new "model"
                    ]
                , expression =
                    CodeGen.Expression.caseExpression
                        { value = CodeGen.Argument.new "msg"
                        , branches =
                            [ { name = "UrlRequested"
                              , arguments = [ CodeGen.Argument.new "(Browser.Internal url)" ]
                              , expression =
                                    CodeGen.Expression.multilineTuple
                                        [ CodeGen.Expression.value "model"
                                        , CodeGen.Expression.function
                                            { name = "Browser.Navigation.pushUrl"
                                            , arguments =
                                                [ CodeGen.Expression.value "model.key"
                                                , CodeGen.Expression.value "(Url.toString url)"
                                                ]
                                            }
                                        ]
                              }
                            , { name = "UrlRequested"
                              , arguments = [ CodeGen.Argument.new "(Browser.External url)" ]
                              , expression =
                                    CodeGen.Expression.multilineTuple
                                        [ CodeGen.Expression.value "model"
                                        , CodeGen.Expression.function
                                            { name = "Browser.Navigation.load"
                                            , arguments =
                                                [ CodeGen.Expression.value "url"
                                                ]
                                            }
                                        ]
                              }
                            , { name = "UrlChanged"
                              , arguments = [ CodeGen.Argument.new "url" ]
                              , expression =
                                    CodeGen.Expression.multilineTuple
                                        [ CodeGen.Expression.recordUpdate
                                            { value = "model"
                                            , fields =
                                                [ ( "url", CodeGen.Expression.value "url" )
                                                ]
                                            }
                                        , CodeGen.Expression.value "Cmd.none"
                                        ]
                              }
                            ]
                        }
                }
            , CodeGen.Declaration.function
                { name = "subscriptions"
                , annotation =
                    CodeGen.Annotation.function
                        [ CodeGen.Annotation.type_ "Model"
                        , CodeGen.Annotation.type_ "Sub Msg"
                        ]
                , arguments = [ CodeGen.Argument.new "model" ]
                , expression = CodeGen.Expression.value "Sub.none"
                }
            , CodeGen.Declaration.comment [ "VIEW" ]
            , CodeGen.Declaration.function
                { name = "view"
                , annotation =
                    CodeGen.Annotation.function
                        [ CodeGen.Annotation.type_ "Model"
                        , CodeGen.Annotation.type_ "Browser.Document Msg"
                        ]
                , arguments = [ CodeGen.Argument.new "model" ]
                , expression =
                    CodeGen.Expression.multilineRecord
                        [ ( "title", CodeGen.Expression.string "App" )
                        , ( "body"
                          , CodeGen.Expression.list
                                [ CodeGen.Expression.function
                                    { name = "viewPage"
                                    , arguments =
                                        [ CodeGen.Expression.value "model"
                                        ]
                                    }
                                ]
                          )
                        ]
                }
            , let
                toViewBranch :
                    PageFile
                    ->
                        { name : String
                        , arguments : List CodeGen.Argument.Argument
                        , expression : CodeGen.Expression.Expression
                        }
                toViewBranch pageFile =
                    let
                        filepath : Filepath
                        filepath =
                            PageFile.toFilepath pageFile

                        conditionallyWrapInLayout : CodeGen.Expression -> CodeGen.Expression
                        conditionallyWrapInLayout pageExpression =
                            case PageFile.toLayoutName pageFile of
                                Just layoutName ->
                                    CodeGen.Expression.multilineFunction
                                        { name = "Layouts." ++ layoutName ++ ".layout"
                                        , arguments =
                                            [ CodeGen.Expression.multilineRecord
                                                [ ( "page", pageExpression )
                                                ]
                                            ]
                                        }

                                Nothing ->
                                    pageExpression
                    in
                    if Filepath.hasDynamicParameters filepath then
                        { name = "Route." ++ Filepath.toRouteVariantName filepath
                        , arguments = [ CodeGen.Argument.new "params" ]
                        , expression =
                            conditionallyWrapInLayout
                                (CodeGen.Expression.function
                                    { name = Filepath.toPageModuleName filepath ++ ".page"
                                    , arguments =
                                        [ CodeGen.Expression.value "params"
                                        ]
                                    }
                                )
                        }

                    else
                        { name = "Route." ++ Filepath.toRouteVariantName filepath
                        , arguments = []
                        , expression =
                            conditionallyWrapInLayout
                                (CodeGen.Expression.value (Filepath.toPageModuleName filepath ++ ".page"))
                        }
              in
              CodeGen.Declaration.function
                { name = "viewPage"
                , annotation =
                    CodeGen.Annotation.function
                        [ CodeGen.Annotation.type_ "Model"
                        , CodeGen.Annotation.type_ "Html Msg"
                        ]
                , arguments = [ CodeGen.Argument.new "model" ]
                , expression =
                    CodeGen.Expression.caseExpression
                        { value = CodeGen.Argument.new "Route.fromUrl model.url"
                        , branches =
                            List.concat
                                [ data.pages
                                    |> List.map toViewBranch
                                , [ { name = "Route.NotFound_"
                                    , arguments = []
                                    , expression = CodeGen.Expression.value "Pages.NotFound_.page"
                                    }
                                  ]
                                ]
                        }
                }
            ]
        }


routeElmModule : Data -> CodeGen.Module
routeElmModule data =
    CodeGen.Module.new
        { name = [ "Route" ]
        , exposing_ = [ "Route(..)", "fromUrl" ]
        , imports =
            [ CodeGen.Import.new [ "Url" ]
                |> CodeGen.Import.withExposing [ "Url" ]
            , CodeGen.Import.new [ "Url.Parser" ]
                |> CodeGen.Import.withExposing [ "(</>)" ]
            ]
        , declarations =
            [ CodeGen.Declaration.customType
                { name = "Route"
                , variants =
                    List.concat
                        [ data.pages
                            |> List.map PageFile.toFilepath
                            |> List.map Filepath.toRouteVariant
                        , [ ( "NotFound_", [] ) ]
                        ]
                }
            , CodeGen.Declaration.function
                { name = "fromUrl"
                , annotation =
                    CodeGen.Annotation.function
                        [ CodeGen.Annotation.type_ "Url"
                        , CodeGen.Annotation.type_ "Route"
                        ]
                , arguments = [ CodeGen.Argument.new "url" ]
                , expression =
                    CodeGen.Expression.pipeline
                        [ CodeGen.Expression.function
                            { name = "Url.Parser.parse"
                            , arguments =
                                [ CodeGen.Expression.value "parser"
                                , CodeGen.Expression.value "url"
                                ]
                            }
                        , CodeGen.Expression.function
                            { name = "Maybe.withDefault"
                            , arguments =
                                [ CodeGen.Expression.value "NotFound_"
                                ]
                            }
                        ]
                }
            , CodeGen.Declaration.function
                { name = "parser"
                , annotation = CodeGen.Annotation.type_ "Url.Parser.Parser (Route -> a) a"
                , arguments = []
                , expression =
                    CodeGen.Expression.multilineFunction
                        { name = "Url.Parser.oneOf"
                        , arguments =
                            [ data.pages
                                |> List.map PageFile.toFilepath
                                |> List.map Filepath.toUrlParser
                                |> CodeGen.Expression.multilineList
                            ]
                        }
                }
            ]
        }


{-|

    module ElmLand.Layout exposing (Layout(..))

    type Layout
        = Default
        | Sidebar

-}
elmLandLayoutsElmModule : Data -> CodeGen.Module
elmLandLayoutsElmModule data =
    CodeGen.Module.new
        { name = [ "ElmLand", "Layout" ]
        , exposing_ = [ "Layout(..)" ]
        , imports = []
        , declarations =
            [ CodeGen.Declaration.customType
                { name = "Layout"
                , variants =
                    data.layouts
                        |> List.map Filepath.toRouteVariant
                }
            ]
        }


notFoundModule : CodeGen.Module
notFoundModule =
    CodeGen.Module.new
        { name = [ "Pages", "NotFound_" ]
        , exposing_ = [ "page" ]
        , imports =
            [ CodeGen.Import.new [ "Html" ]
                |> CodeGen.Import.withExposing [ "Html" ]
            ]
        , declarations =
            [ CodeGen.Declaration.function
                { name = "page"
                , arguments = []
                , annotation = CodeGen.Annotation.type_ "Html msg"
                , expression =
                    CodeGen.Expression.function
                        { name = "Html.text"
                        , arguments = [ CodeGen.Expression.string "Page not found..." ]
                        }
                }
            ]
        }


type alias Data =
    { pages : List PageFile
    , layouts : List Filepath
    }


decoder : Json.Decode.Decoder Data
decoder =
    Json.Decode.map2 Data
        (Json.Decode.field "pages" (Json.Decode.list PageFile.decoder))
        (Json.Decode.field "layouts" (Json.Decode.list Filepath.decoder))
