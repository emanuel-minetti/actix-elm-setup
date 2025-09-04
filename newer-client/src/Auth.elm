module Auth exposing (User, onPageLoad, viewCustomPage)

import Auth.Action
import Dict
import Route exposing (Route)
import Route.Path
import Shared
import User
import View exposing (View)


type alias User =
    User.User


{-| Called before an auth-only page is loaded.
-}
onPageLoad : Shared.Model -> Route () -> Auth.Action.Action User
onPageLoad shared route =
    case shared.user of
        Just user ->
            Auth.Action.LoadPageWithUser user

        Nothing ->
            Auth.Action.pushRoute
                { path = Route.Path.Login
                , query = Dict.fromList [ ( "from", route.url.path ) ]
                , hash = Nothing
                }


{-| Renders whenever `Auth.Action.loadCustomPage` is returned from `onPageLoad`.
-}
viewCustomPage : Shared.Model -> Route () -> View Never
viewCustomPage _ _ =
    View.fromString "Loading..."
