// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
const flags = ({ env }) => {
    const lang = localStorage.getItem("lang") ?? navigator.language;
    return {
        flags: {lang: lang}
    };
}

// This is called AFTER your Elm app starts up
//
// Here you can work with `app.ports` to send messages
// to your Elm application, or subscribe to incoming
// messages from Elm
const onReady = ({ app, env }) => {

}