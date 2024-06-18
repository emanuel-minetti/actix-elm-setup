use actix_files::NamedFile;

pub async fn return_favicon() -> Result<NamedFile, std::io::Error> {
    NamedFile::open("../public/favicon.ico")
}

pub async fn return_index() -> Result<NamedFile, std::io::Error> {
    NamedFile::open("../public/index.html")
}

pub async fn return_elm() -> Result<NamedFile, std::io::Error> {
    NamedFile::open("../public/elm.js")
}