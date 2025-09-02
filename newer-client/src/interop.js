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