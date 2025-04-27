;credit: https://github.com/TheArkive/JXON_ahk2
;credit: https://github.com/thqby/ahk2_lib
#Include _JSONS.ahk
#Include requests.ahk
/**
 * @filesource https://github.com/samfisherirl/Github.ahk-API-for-AHKv2
 */

/**
 * Fetches the latest release information from a GitHub repository.
 * @function
 * @name Github.latest
 * @param {string} Username - The username of the repository owner.
 * @param {string} Repository_Name - The name of the repository.
 * @returns {Object} An object containing the download URLs, version, change notes, and date of the latest release.
 */

/**
 * Fetches the historic release information from a GitHub repository.
 * @function
 * @name Github.historicReleases
 * @param {string} Username - The username of the repository owner.
 * @param {string} Repository_Name - The name of the repository.
 * @returns {Array.<Object>} An array of objects, each containing the download URL, version, change notes, and date of a historic release.
 */

/**
 * Downloads a file from a given URL to a specified path.
 * @function
 * @name Github.Download
 * @param {string} url - The URL of the file to download.
 * @param {string} path - The path where the file should be saved.
 * @description This function improves on the basic download function by applying the proper extension if the user provides a wrong one, and allowing the user to provide a directory.
 * @example
 * // Providing A_ScriptDir to Download will throw error
 * // Providing A_ScriptDir to Github.Download() will supply Download() with release name 
 */
class Github
{
    static source_zip := ""
    static url := false
    static usernamePlusRepo := false
    static storage := {
        repo: "",
        source_zip: ""
    }
    static data := false

    static build(Username, Repository_Name) {
        Github.usernamePlusRepo := Trim(Username) "/" Trim(Repository_Name)
        Github.source_zip := "https://github.com/" Github.usernamePlusRepo "/archive/refs/heads/main.zip"
        return "https://api.github.com/repos/" Github.usernamePlusRepo "/releases"
        ;filedelete, "1.json"
        ;this.Filetype := data["assets"][1]["browser_download_url"]
    }
    /*
    return {
        downloadURLs: [
            "http://github.com/release.zip",
            "http://github.com/release.rar"
                    ],
        version: "",
        change_notes: "",
        date: "",
        }
    */
    static latest(Username := "", Repository_Name := "") {
        if (Username != "") & (Repository_Name != "") {
            url := Github.build(Username, Repository_Name)
            data := Github.processRepo(url)
            return Github.latestProp(data)
        }
    }
    /*
    static processRepo(url) {
        Github.source_zip := "https://github.com/" Github.usernamePlusRepo "/archive/refs/heads/main.zip"
        Github.data := Github.jsonDownload(url)
        data := Github.data
        return json.Load(&data)
    }
    */
    static processRepo(url) {
        Github.source_zip := "https://github.com/" Github.usernamePlusRepo "/archive/refs/heads/main.zip"
        data := Github.jsonDownload(url)
        return Json.Load(&data)
    }
    /*
    @example
    repoArray := Github.historicReleases()
        repoArray[1].downloadURL => string | link
        repoArray[1].version => string | version data
        repoArray[1].change_notes => string | change notes
        repoArray[1].date => string | date of release
    
    @returns (array of release objects) => [{
        downloadURL: "",
        version: "",
        change_notes: "",
        date: ""
        }]
    */
    static historicReleases(Username, Repository_Name) {
        url := Github.build(Username, Repository_Name)
        data := Github.processRepo(url)
        repo_storage := []
        url := "https://api.github.com/repos/" Github.usernamePlusRepo "/releases"
        data := Github.jsonDownload(url)
        data := json.Load(&data)
        for release in data {
            for asset in release["assets"] {
                repo_storage.Push(Github.repoDistribution(release, asset))
            }
        }
        return repo_storage
    }
    static latestProp(data) {
        for i in data {
            baseData := i
            assetMap := i["assets"]
            date := i["created_at"]
            if i["assets"].Length > 0 {
                length := i["assets"].Length
                releaseArray := Github.distributeReleaseArray(length, assetMap)
                break
            }
            else {
                releaseArray := ["https://github.com/" Github.usernamePlusRepo "/archive/" i["tag_name"] ".zip"]
                ;source url = f"https://github.com/{repo_owner}/{repo_name}/archive/{release_tag}.zip"
                break
            }
        }
        ;move release array to first if
        ;then add source
        return {
            downloadURLs: releaseArray,
            version: baseData["tag_name"],
            change_notes: baseData["body"],
            date: date
        }
    }
    /*
    loop releaseURLCount {
        assetArray.Push(JsonData[A_Index]["browser_download_url"])
    }
    return => assetArray[]
    */
    /*
    loop releaseURLCount {
        assetMap.Set(jsonData[A_Index]["name"], jsonData[A_Index]["browser_download_url"])
    }
    return => assetMap()
    */
    static jsonDownload(URL) {
        Http := WinHttpRequest()
        Http.Open("GET", URL)
        Http.Send()
        Http.WaitForResponse()
        storage := Http.ResponseText
        return storage ;Set the "text" variable to the response
    }
    static distributeReleaseArray(releaseURLCount, Jdata) {
        assetArray := []
        if releaseURLCount {
            if (releaseURLCount > 1) {
                loop releaseURLCount {
                    assetArray.Push(Jdata[A_Index]["browser_download_url"])
                }
            }
            else {
                assetArray.Push(Jdata[1]["browser_download_url"])
            }
            return assetArray
        }
    }
    /*
    download the latest main.zip source zip
    */
    static Source(Username, Repository_Name, Pathlocal := A_ScriptDir) {
        url := Github.build(Username, Repository_Name)
        data := Github.processRepo(url)

        Github.Download(URL := Github.source_zip, PathLocal)
    }
    /*
    benefit over download() => handles users path, and applies appropriate extension. 
    IE: If user provides (Path:=A_ScriptDir "\download.zip") but extension is .7z, extension is modified for the user. 
    If user provides directory, name for file is applied from the path (download() will not).
    Download (
        @param URL to download
        @param Path where to save locally
    )
    */
    static Download(URL, PathLocal := A_ScriptDir) {
        releaseExtension := Github.downloadExtensionSplit(URL)
        pathWithExtension := Github.handleUserPath(PathLocal, releaseExtension)
        try {
            Download(URL, pathWithExtension)
        } catch as e {
            MsgBox(e.Message . "`nURL:`n" URL)
        }
    }
    static emptyRepoMap() {
        repo := {
            downloadURL: "",
            version: "",
            change_notes: "",
            date: "",
            name: ""
        }
        return repo
    }

    static repoDistribution(release, asset) {
        return {
            downloadURL: asset["browser_download_url"],
            version: release["tag_name"],
            change_notes: release["body"],
            date: asset["created_at"],
            name: asset["name"]
        }
    }
    static downloadExtensionSplit(DL) {
        Arrays := StrSplit(DL, ".")
        filetype := Trim(Arrays[Arrays.Length])
        return filetype
    }

    static handleUserPath(PathLocal, releaseExtension) {
        if InStr(PathLocal, "\") {
            pathParts := StrSplit(PathLocal, "\")
            FileName := pathParts[pathParts.Length]
        }
        else {
            FileName := PathLocal
            PathLocal := A_ScriptDir "\" FileName
            pathParts := StrSplit(PathLocal, "\")
        }
        if InStr(FileName, ".") {
            FileNameParts := StrSplit(FileName, ".")
            UserExtension := FileNameParts[FileNameParts.Length]
            if (releaseExtension != userExtension) {
                newName := ""
                for key, val in FileNameParts {
                    if (A_Index == FileNameParts.Length) {
                        break
                    }
                    newName .= val
                }
                newPath := ""
                for key, val in pathParts {
                    if (A_Index == pathParts.Length) {
                        break
                    }
                    newPath .= val
                }
                pathWithExtension := newPath newName "." releaseExtension
            }
            else {
                pathWithExtension := PathLocal
            }
        }
        else {
            pathWithExtension := PathLocal "." releaseExtension
        }
        return pathWithExtension
    }
}
;;;; AHK v2 - https://github.com/TheArkive/JXON_ahk2
;MIT License
;Copyright (c) 2021 TheArkive
;Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
;The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;
; originally posted by user coco on AutoHotkey.com
; https://github.com/cocobelgica/AutoHotkey-JSON

; https://github.com/cocobelgica/AutoHotkey-JSON
