// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
const flags = ({ env }) => {
    const lang = localStorage.getItem("lang")
        ? localStorage.getItem("lang").toLowerCase() : navigator.language;
    const savedSessionToken = localStorage.getItem("token") ?? '';
    const expires = !isNaN(Number.parseInt(localStorage.getItem("expires")))
        ? Number.parseInt(localStorage.getItem("expires")) : 0;
    const nowPlusSome = (new Date().getMilliseconds()) + 10000;
    return {lang, savedSessionToken, expires, nowPlusSome}
}