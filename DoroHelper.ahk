#Requires AutoHotkey >=v2.0
#Include %A_ScriptDir%\lib\github.ahk
CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
;操作间隔（单位：毫秒）
sleepTime := 1500
scrRatio := 1.0
;consts
stdScreenW := 3840
stdScreenH := 2160
waitTolerance := 50
colorTolerance := 15
currentVersion := "v0.1.23"
usr := "kyokakawaii"
repo := "DoroHelper"
;颜色判断
IsSimilarColor(targetColor, color) {
    tr := Format("{:d}", "0x" . substr(targetColor, 3, 2))
    tg := Format("{:d}", "0x" . substr(targetColor, 5, 2))
    tb := Format("{:d}", "0x" . substr(targetColor, 7, 2))
    pr := Format("{:d}", "0x" . substr(color, 3, 2))
    pg := Format("{:d}", "0x" . substr(color, 5, 2))
    pb := Format("{:d}", "0x" . substr(color, 7, 2))
    ;MsgBox tr tg tb pr pg pb
    distance := sqrt((tr - pr) ** 2 + (tg - pg) ** 2 + (tb - pb) ** 2)
    if (distance < colorTolerance)
        return true
    return false
}
;检查更新
CheckForUpdateHandler(isManualCheck) {
    global currentVersion, usr, repo ; 确保能访问全局变量
    try {
        latestObj := Github.latest(usr, repo)
        if (currentVersion != latestObj.version) {
            userResponse := MsgBox( ; 发现新版本
                "DoroHelper存在更新版本:`n"
                "`nVersion: " latestObj.version
                "`nNotes:`n"
                . latestObj.change_notes
                "`n`n是否下载?", , "36") ; 0x24 = Yes/No + Question Icon
            if (userResponse = "Yes") {
                ; 用户选择下载
                downloadTempName := "DoroDownload.exe" ; 临时文件名
                finalName := "DoroHelper-" latestObj.version ".exe"
                try {
                    Github.Download(latestObj.downloadURLs[1], A_ScriptDir "\" downloadTempName)
                    ; 下载成功后重命名
                    FileMove(A_ScriptDir "\" downloadTempName, A_ScriptDir "\" finalName, 1) ; 1 = overwrite
                    MsgBox("新版本已下载至当前目录: " finalName, "下载完成")
                    ExitApp ; 下载完成后退出当前脚本
                } catch as downloadError {
                    MsgBox("下载失败，请检查网络。`n(" downloadError.Message ")", "下载错误", "IconX")
                    ; 删除临时文件
                    if FileExist(A_ScriptDir "\" downloadTempName)
                        FileDelete(A_ScriptDir "\" downloadTempName)
                }
            }
            ; else 用户选择不下载，什么也不做
        } else {
            ; 没有新版本
            if (isManualCheck) { ; 只有手动检查时才提示
                MsgBox("当前Doro已是最新版本。", "检查更新")
            }
        }
    } catch as githubError {
        ; 只有手动检查时才提示连接错误，自动检查时静默失败
        if (isManualCheck) {
            MsgBox("检查更新失败，无法连接到Github或仓库信息错误。`n(" githubError.Message ")", "检查更新错误", "IconX")
        }
    }
}
ClickOnCheckForUpdate(*) {
    CheckForUpdateHandler(true) ; 调用核心函数，标记为手动检查
}
;坐标转换-点击
UserClick(sX, sY, k) {
    uX := Round(sX * k)
    uY := Round(sY * k)
    Send "{Click " uX " " uY "}"
}
;坐标转换-颜色
UserCheckColor(sX, sY, sC, k) {
    loop sX.Length {
        uX := Round(sX[A_Index] * k)
        uY := Round(sY[A_Index] * k)
        uC := PixelGetColor(uX, uY)
        if (!IsSimilarColor(uC, sC[A_Index]))
            return 0
    }
    return 1
}
;判断自动按钮颜色
isAutoOff(sX, sY, k) {
    uX := Round(sX * k)
    uY := Round(sY * k)
    uC := PixelGetColor(uX, uY)
    r := Format("{:d}", "0x" . substr(uC, 3, 2))
    g := Format("{:d}", "0x" . substr(uC, 5, 2))
    b := Format("{:d}", "0x" . substr(uC, 7, 2))
    if Abs(r - g) < 10 && Abs(r - b) < 10 && Abs(g - b) < 10
        return true
    return false
}
;检查自动瞄准和自动爆裂按钮颜色
CheckAutoBattle() {
    static autoBurstOn := false
    static autoAimOn := false
    ; 检查并开启自动瞄准 (Auto Aim)
    if !autoAimOn && UserCheckColor([216], [160], ["0xFFFFFF"], scrRatio) {
        ; 如果自动瞄准按钮是灰色/关闭状态
        if isAutoOff(60, 57, scrRatio) {
            UserClick(60, 71, scrRatio) ; 点击开启自动瞄准
            Sleep sleepTime
        }
        autoAimOn := true ; 设置标志位，表示已尝试开启或已开启
    }
    ; 检查并开启自动爆裂 (Auto Burst)
    if !autoBurstOn && UserCheckColor([216], [160], ["0xFFFFFF"], scrRatio) { ; 假设检查点与 Auto Aim 相同
        ; 如果自动爆裂按钮是灰色/关闭状态
        if isAutoOff(202, 66, scrRatio) {
            Send "{Tab}" ; 发送 Tab 键尝试开启自动爆裂
            Sleep sleepTime
        }
        autoBurstOn := true ; 设置标志位，表示已尝试开启或已开启
    }
}
;登录
Login() {
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if UserCheckColor([1973, 1969], [1368, 1432], ["0x00ADFB", "0x00ADFB"], scrRatio) {
            UserClick(2127, 1400, scrRatio)
            Sleep sleepTime
        }
        if UserCheckColor([1965, 1871], [1321, 1317], ["0x00A0EB", "0xF7F7F7"], scrRatio) {
            UserClick(2191, 1350, scrRatio)
            Sleep sleepTime
        }
        if UserCheckColor([1720, 2111], [1539, 1598], ["0x00AEFF", "0x00AEFF"], scrRatio) {
            UserClick(1905, 1568, scrRatio)
            Sleep sleepTime
        }
        if A_Index > waitTolerance * 50 {
            MsgBox "登录失败！"
            ExitApp
        }
    }
}
;返回大厅
BackToHall() {
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
;1: 防御前哨基地奖励
OutpostDefence() {
    ; --- 函数开始 --- (移除了 Start: 标签)
    stdTargetX := 1092
    stdTargetY := 1795
    UserClick(stdTargetX, stdTargetY, scrRatio) ; 点击进入前哨基地
    Sleep sleepTime
    ; 等待进入前哨基地的标准检查点
    stdCkptX := [1500, 1847]
    stdCkptY := [1816, 1858]
    desiredColor := ["0xF8FCFD", "0xF7FCFD"]
    loopCounter := 0 ; 独立的循环计数器
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        loopCounter += 1
        if loopCounter > waitTolerance { ; 使用独立的计数器判断超时
            MsgBox "进入防御前哨失败！ (超时)"
            ExitApp
        }
        if loopCounter > 10 { ; 尝试次数过多，可能卡住
            MsgBox "进入防御前哨尝试次数过多，退出。"
            ; 可以选择是否在退出前尝试返回大厅
            ExitApp
        }
    }
    ; 点击 "一举歼灭" 按钮
    stdTargetX := 1686
    stdTargetY := 1846
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    ; 等待 "一举歼灭" 界面加载完成（通过检查点消失判断）
    stdCkptX := [1500, 1847] ; 使用与进入时相同的检查点
    stdCkptY := [1816, 1858]
    desiredColor := ["0xF8FCFD", "0xF7FCFD"]
    loopCounter := 0 ; 重置计数器
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ; 持续点击直到界面变化
        Sleep sleepTime
        loopCounter += 1
        if loopCounter > waitTolerance {
            MsgBox "进入一举歼灭失败！ (超时)"
            ExitApp
        }
        if loopCounter > 10 {
            MsgBox "进入一举歼灭尝试次数过多，退出。"
            ExitApp
        }
    }
    ; 检查是否有免费扫荡次数 (按钮非灰色)
    sweepCkptX := [1933]
    sweepCkptY := [1648]
    sweepGrayColor := ["0xE9ECF0"] ; 灰色按钮颜色
    if !UserCheckColor(sweepCkptX, sweepCkptY, sweepGrayColor, scrRatio) {
        ; --- 如果有免费次数，执行扫荡 ---
        sweepTargetX := 2093 ; 扫荡按钮 X
        sweepTargetY := 1651 ; 扫荡按钮 Y
        UserClick(sweepTargetX, sweepTargetY, scrRatio)
        Sleep sleepTime
        sweepConfirmCkptX := [1933] ; 扫荡确认界面检查点 X
        sweepConfirmCkptY := [1648] ; 扫荡确认界面检查点 Y
        sweepConfirmColor := ["0x11ADF5"] ; 扫荡确认界面特征颜色
        loopCounter := 0 ; 重置计数器
        while UserCheckColor(sweepConfirmCkptX, sweepConfirmCkptY, sweepConfirmColor, scrRatio) {
            UserClick(sweepTargetX, sweepTargetY, scrRatio) ; 持续点击扫荡按钮直到确认界面消失
            Sleep sleepTime
            ; 检查并处理可能的次级弹窗 (例如资源不足提示)
            if UserCheckColor([2088], [1327], ["0x00A0EB"], scrRatio) {
                UserClick(2202, 1342, scrRatio) ; 点击次级弹窗确认
                Sleep sleepTime ; 等待次级弹窗消失
            }
            loopCounter += 1
            if loopCounter > 10 { ; 设置扫荡确认的超时次数
                MsgBox "扫荡确认超时，退出。"
                ExitApp
            }
        }
    }
    popupCkptX := [2356]
    popupCkptY := [1870]
    popupDesiredColor := ["0x0EAFF4"]
    popupTargetX := 2156
    popupTargetY := 1846
    popupLoopCounter := 0 ; 为此弹窗处理循环设置独立计数器
    while !UserCheckColor(popupCkptX, popupCkptY, popupDesiredColor, scrRatio) {
        UserClick(popupTargetX, popupTargetY, scrRatio) ; 点击确认按钮区域
        Sleep sleepTime
        ; 检查并处理另一个可能的次级弹窗
        if UserCheckColor([2088], [1327], ["0x00A0EB"], scrRatio) {
            UserClick(2202, 1342, scrRatio) ; 点击次级弹窗的确认
            Sleep sleepTime ; 等待次级弹窗消失
        }
        popupLoopCounter += 1
        if popupLoopCounter > 10 { ; 设置一个合理的超时次数
            MsgBox("处理弹窗超时，退出。")
            ExitApp
        }
    }
    ; 点击 "获得奖励" 按钮
    rewardTargetX := 2156
    rewardTargetY := 1846
    UserClick(rewardTargetX, rewardTargetY, scrRatio)
    Sleep sleepTime
    ; 等待返回大厅
    hallCkptX := [64]
    hallCkptY := [470]
    hallDesiredColor := ["0xFAA72C"]
    loopCounter := 0 ; 重置计数器
    while !UserCheckColor(hallCkptX, hallCkptY, hallDesiredColor, scrRatio) {
        UserClick(rewardTargetX, rewardTargetY, scrRatio) ; 持续点击直到返回大厅
        Sleep sleepTime
        ; 再次检查并处理可能的次级弹窗
        if UserCheckColor([2088], [1327], ["0x00A0EB"], scrRatio) {
            UserClick(2202, 1342, scrRatio)
            Sleep sleepTime
        }
        loopCounter += 1
        if loopCounter > waitTolerance { ; 使用全局超时容忍度
            MsgBox("前哨基地防御奖励领取后返回大厅异常！ (超时)")
            ExitApp
        }
    }
}
;2: 付费商店每日每周免费钻
CashShop() {
    ;进入商店
    stdTargetX := 1163
    stdTargetY := 1354
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [158, 199]
    stdCkptY := [525, 439]
    desiredColor := ["0x0DC2F4", "0x3B3E41"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        if UserCheckColor([2047], [1677], ["0x00A0EB"], scrRatio) or UserCheckColor([2047], [1677], ["0x9A9B9A"],
        scrRatio) {
            UserClick(1789, 1387, scrRatio)
            Sleep sleepTime
            UserClick(1789, 1387, scrRatio)
            Sleep sleepTime
            UserClick(2144, 1656, scrRatio)
            Sleep sleepTime
            while UserCheckColor([2047], [1677], ["0x00A0EB"], scrRatio) {
                UserClick(2144, 1656, scrRatio)
                Sleep sleepTime
            }
            break
        }
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if UserCheckColor([2088], [1327], ["0x00A0EB"], scrRatio) {
            UserClick(2202, 1342, scrRatio)
        }
        if A_Index > waitTolerance {
            MsgBox "进入付费商店失败！"
            ExitApp
        }
    }
    Sleep sleepTime
    if UserCheckColor([2047], [1677], ["0x00A0EB"], scrRatio) or UserCheckColor([2047], [1677], ["0x9A9B9A"], scrRatio) {
        UserClick(1789, 1387, scrRatio)
        Sleep sleepTime
        UserClick(1789, 1387, scrRatio)
        Sleep sleepTime
        UserClick(2144, 1656, scrRatio)
        Sleep sleepTime
        while UserCheckColor([2047], [1677], ["0x00A0EB"], scrRatio) {
            UserClick(2144, 1656, scrRatio)
            Sleep sleepTime
        }
    }
    delta := false
    stdCkptX := [52]
    stdCkptY := [464]
    desiredColor := ["0xF7FCFD"]
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
        delta := true
    stdTargetX := 256
    if delta
        stdTargetX := 432
    stdTargetY := 486
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [194]
    if delta
        stdCkptX := [373]
    stdCkptY := [436]
    desiredColor := ["0x0FC7F5"]
    if delta
        desiredColor := ["0x0BC7F4"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入礼包页面失败！"
            ExitApp
        }
    }
    stdCkptX := [514]
    stdCkptY := [1018]
    desiredColor := ["0xF2F8FC"]
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        stdTargetX := stdTargetX - 172
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
    }
    del := 336
    stdCkptX := [1311]
    stdCkptY := [612]
    desiredColor := ["0xA0A0AC"]
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
        del := 0
    ;每日
    stdTargetX := 545 - del
    stdTargetY := 610
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [431 - del]
    stdCkptY := [594]
    desiredColor := ["0x0EC7F5"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入每日礼包页面失败！"
            ExitApp
        }
    }
    stdTargetX := 212
    stdTargetY := 1095
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    ;每周
    stdTargetX := 878 - del
    stdTargetY := 612
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [769 - del]
    stdCkptY := [600]
    desiredColor := ["0x0CC8F4"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入每周礼包页面失败！"
            ExitApp
        }
    }
    stdTargetX := 212
    stdTargetY := 1095
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    ;每月
    stdTargetX := 1211 - del
    stdTargetY := 612
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1114 - del]
    stdCkptY := [600]
    desiredColor := ["0x0CC8F4"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入每月礼包页面失败！"
            ExitApp
        }
    }
    stdTargetX := 212
    stdTargetY := 1095
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    ;回到大厅
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "退出付费商店失败！"
            ExitApp
        }
    }
}
;3: 免费商店 - 判断指定坐标的颜色对应哪种手册，并返回用户是否勾选了购买该手册
BuyThisBook(coor, k) {
    global g_settings ; <--- 添加对全局 g_settings 的访问
    uX := Round(coor[1] * k)
    uY := Round(coor[2] * k)
    uC := PixelGetColor(uX, uY)
    ; 将十六进制颜色代码转换为 RGB 十进制值
    R := Format("{:d}", "0x" . SubStr(uC, 3, 2))
    G := Format("{:d}", "0x" . SubStr(uC, 5, 2))
    B := Format("{:d}", "0x" . SubStr(uC, 7, 2))
    ; 判断颜色并返回对应的 g_settings 值 (用户是否勾选了购买)
    if (B > G and B > R) {
        ; 蓝色为主 -> 水冷手册 ("BookWater")
        return g_settings["BookWater"] ;
    }
    if (G > R and G > B) {
        ; 绿色为主 -> 风压手册 ("BookWind")
        return g_settings["BookWind"] ;
    }
    if (R > G and G > B and G > 80) {
        ; 铁甲手册 ("BookIron")
        return g_settings["BookIron"] ;
    }
    if (R > B and B > G and B > 80) {
        ; 电击手册 ("BookElec")
        return g_settings["BookElec"]
    }
    ; 默认情况或主要是纯红色 -> 燃烧手册 ("BookFire")
    return g_settings["BookFire"] ;  (作为默认或纯红色的情况)
}
; 白嫖一次普通商店
ShopFreeClaim() {
    local claimTargetX, claimTargetY, confirmCkptX, confirmCkptY, confirmColor, confirmTargetX, confirmTargetY,
        shopCkptX, shopCkptY, shopColor, loopCounter ; 使用 local 避免污染全局
    ; --- 点击领取按钮 ---
    claimTargetX := 383
    claimTargetY := 1480
    UserClick(claimTargetX, claimTargetY, scrRatio)
    Sleep sleepTime
    ; --- 等待确认弹窗 ---
    confirmCkptX := [2063]
    confirmCkptY := [1821]
    confirmColor := ["0x079FE4"]
    loopCounter := 0
    while !UserCheckColor(confirmCkptX, confirmCkptY, confirmColor, scrRatio) {
        UserClick(claimTargetX, claimTargetY, scrRatio) ; 如果没等到，再点一下领取按钮
        Sleep sleepTime // 2
        loopCounter += 1
        if loopCounter > waitTolerance {
            MsgBox "普通商店免费领取：等待确认弹窗超时！"
            ExitApp
        }
    }
    ; --- 点击确认按钮 ---
    confirmTargetX := 2100
    confirmTargetY := 1821
    UserClick(confirmTargetX, confirmTargetY, scrRatio)
    Sleep sleepTime
    ; --- 等待返回商店主界面 ---
    shopCkptX := [118]
    shopCkptY := [908]
    shopColor := ["0xF99217"]
    loopCounter := 0
    while !UserCheckColor(shopCkptX, shopCkptY, shopColor, scrRatio) {
        UserClick(confirmTargetX, confirmTargetY, scrRatio) ; 如果没等到，再点一下确认按钮
        Sleep sleepTime // 2
        loopCounter += 1
        if loopCounter > waitTolerance {
            MsgBox "普通商店免费领取：等待返回商店界面超时！"
            ExitApp
        }
    }
    ; --- 单次免费领取完成 ---
}
FreeShop(numOfBook) {
    global g_settings, isBoughtTrash, scrRatio, sleepTime, waitTolerance ; 确保访问全局变量
    ;进入商店
    stdTargetX := 1193
    stdTargetY := 1487
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    shopCkptX := [118]
    shopCkptY := [908]
    shopDesiredColor := ["0xF99217"] ; 商店主界面特征颜色
    loopCounter := 0
    while !UserCheckColor(shopCkptX, shopCkptY, shopDesiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ; 点击进入商店
        Sleep sleepTime
        loopCounter += 1
        if loopCounter > waitTolerance {
            MsgBox "进入普通商店失败！"
            ExitApp
        }
    }
    ; 检查第一次免费领取是否可用 (按钮非蓝色)
    firstClaimCkptX := [349]
    firstClaimCkptY := [1305]
    firstClaimUsedColor := ["0x127CD7"] ; 领取过的按钮颜色
    if !UserCheckColor(firstClaimCkptX, firstClaimCkptY, firstClaimUsedColor, scrRatio) {
        ShopFreeClaim() ; 执行第一次免费领取
        ; 检查是否还有第二次免费次数 (刷新按钮是否有红点)
        refreshCkptX := [697]
        refreshCkptY := [949]
        refreshAvailableColor := ["0xFB5C24"] ; 有免费刷新次数的红点颜色
        if UserCheckColor(refreshCkptX, refreshCkptY, refreshAvailableColor, scrRatio) {
            ; --- 执行刷新操作 ---
            refreshTargetX := 476
            refreshTargetY := 981
            UserClick(refreshTargetX, refreshTargetY, scrRatio) ; 点击刷新按钮
            Sleep sleepTime
            ; 等待刷新确认弹窗
            refreshPopupCkptX := [2133]
            refreshPopupCkptY := [1345]
            refreshPopupColor := ["0x00A0EB"]
            loopCounter := 0 ; 重置计数器
            while !UserCheckColor(refreshPopupCkptX, refreshPopupCkptY, refreshPopupColor, scrRatio) {
                UserClick(refreshTargetX, refreshTargetY, scrRatio) ; 继续点刷新
                Sleep sleepTime // 2
                loopCounter += 1
                if loopCounter > waitTolerance {
                    MsgBox "普通商店刷新：等待确认弹窗超时！"
                    ExitApp
                }
            }
            ; 点击刷新确认按钮
            refreshConfirmX := 2221
            refreshConfirmY := 1351
            UserClick(refreshConfirmX, refreshConfirmY, scrRatio)
            Sleep sleepTime
            ; 等待刷新完成，返回商店主界面
            loopCounter := 0 ; 重置计数器
            ; 点击一个空白区域确保焦点不在按钮上，防止意外点击
            fallbackClickX := 588
            fallbackClickY := 1803
            while !UserCheckColor(shopCkptX, shopCkptY, shopDesiredColor, scrRatio) {
                UserClick(fallbackClickX, fallbackClickY, scrRatio) ; 点击空白区域
                Sleep sleepTime // 2
                loopCounter += 1
                if loopCounter > waitTolerance {
                    MsgBox "普通商店刷新：确认后返回商店超时！"
                    ExitApp
                }
            }
            Sleep 1000 ; 刷新后额外等待一下界面加载
            ShopFreeClaim() ; 执行第二次免费领取
        }
    }
    ;废铁商店检查是否已经购买
    stdTargetX := 137
    stdTargetY := 1737
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [137]
    stdCkptY := [1650]
    desiredColor := ["0xFB931A"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "废铁商店进入异常！"
            ExitApp
        }
    }
    if sleepTime < 1500
        Sleep 500
    global isBoughtTrash
    stdCkptX := [349]
    stdCkptY := [1305]
    desiredColor := ["0x137CD5"]
    if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        isBoughtTrash := 0
    }
    else {
        isBoughtTrash := 1
    }
    ;如果需要，则购买竞技场商店前三本书
    if (numOfBook >= 1 or g_settings["CompanyWeapon"]) {
        stdTargetX := 134
        stdTargetY := 1403
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [134]
        stdCkptY := [1316]
        desiredColor := ["0xFA9318"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime // 2
            if A_Index > waitTolerance {
                MsgBox "竞技场商店进入异常！"
                ExitApp
            }
        }
        if sleepTime < 1500
            Sleep 500
    }
    if numOfBook >= 1 {
        ;购买第一本书
        ;如果今天没买过
        stdCkptX := [349]
        stdCkptY := [1305]
        desiredColor := ["0x127CD7"]
        ;如果今天没买过
        if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) and BuyThisBook([378, 1210], scrRatio) {
            stdTargetX := 384
            stdTargetY := 1486
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [2067]
            stdCkptY := [1770]
            desiredColor := ["0x07A0E4"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index > waitTolerance {
                    MsgBox "第一本书购买异常！"
                    ExitApp
                }
            }
            stdTargetX := 2067
            stdTargetY := 1770
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [134]
            stdCkptY := [1316]
            desiredColor := ["0xFA9318"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index >= 2 {
                    stdTargetX := 2067
                    stdTargetY := 1970
                }
                if A_Index > waitTolerance {
                    MsgBox "第一本书购买异常！"
                    ExitApp
                }
            }
        }
    }
    if numOfBook >= 2 {
        ;购买第二本书
        ;如果今天没买过
        stdCkptX := [673]
        stdCkptY := [1305]
        desiredColor := ["0x137CD5"]
        if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) and BuyThisBook([702, 1210], scrRatio) {
            stdTargetX := 702
            stdTargetY := 1484
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [2067]
            stdCkptY := [1770]
            desiredColor := ["0x07A0E4"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index > waitTolerance {
                    MsgBox "第二本书购买异常！"
                    ExitApp
                }
            }
            stdTargetX := 2067
            stdTargetY := 1770
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [134]
            stdCkptY := [1316]
            desiredColor := ["0xFA9318"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index >= 2 {
                    stdTargetX := 2067
                    stdTargetY := 1970
                }
                if A_Index > waitTolerance {
                    MsgBox "第二本书购买异常！"
                    ExitApp
                }
            }
        }
    }
    if numOfBook >= 3 {
        ;购买第三本书
        ;如果今天没买过
        stdCkptX := [997]
        stdCkptY := [1304]
        desiredColor := ["0x147BD4"]
        if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) and BuyThisBook([1025, 1210], scrRatio) {
            stdTargetX := 1030
            stdTargetY := 1485
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [2067]
            stdCkptY := [1770]
            desiredColor := ["0x07A0E4"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index > waitTolerance {
                    MsgBox "第三本书购买异常！"
                    ExitApp
                }
            }
            stdTargetX := 2067
            stdTargetY := 1770
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [134]
            stdCkptY := [1316]
            desiredColor := ["0xFA9318"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index >= 2 {
                    stdTargetX := 2067
                    stdTargetY := 1970
                }
                if A_Index > waitTolerance {
                    MsgBox "第三本书购买异常！"
                    ExitApp
                }
            }
        }
    }
    if g_settings["CompanyWeapon"] {
        stdCkptX := [2011]
        stdCkptY := [1213]
        desiredColor := ["0xD65E46"]
        if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            stdTargetX := 2017
            stdTargetY := 1485
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [2067]
            stdCkptY := [1770]
            desiredColor := ["0x07A0E4"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index > waitTolerance {
                    MsgBox "公司武器熔炉购买异常！"
                    ExitApp
                }
            }
            stdTargetX := 2067
            stdTargetY := 1770
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [134]
            stdCkptY := [1316]
            desiredColor := ["0xFA9318"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime // 2
                if A_Index >= 2 {
                    stdTargetX := 2067
                    stdTargetY := 1970
                }
                if A_Index > waitTolerance {
                    MsgBox "公司武器熔炉购买异常！"
                    ExitApp
                }
            }
        }
    }
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "退出免费商店失败！"
            ExitApp
        }
    }
}
;4: 派遣
Expedition() {
    ;进入前哨基地
    stdTargetX := 1169
    stdTargetY := 1663
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入前哨基地失败！"
            ExitApp
        }
    }
    stdCkptX := [1907, 1963, 1838, 2034]
    stdCkptY := [1817, 1852, 1763, 1877]
    desiredColor := ["0xFFFFFF", "0xFFFFFF", "0x0B1219", "0x0B1219"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入前哨基地失败！"
            ExitApp
        }
    }
    ;派遣公告栏
    ;收菜
    stdTargetX := 2002
    stdTargetY := 2046
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2113, 2119, 2387]
    stdCkptY := [372, 399, 384]
    desiredColor := ["0x404240", "0x404240", "0x404240"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入派遣失败！"
            ExitApp
        }
    }
    stdTargetX := 2268
    stdTargetY := 1814
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    Sleep 3000
    ;全部派遣
    stdCkptX := [1869, 1977]
    stdCkptY := [1777, 1847]
    desiredColor := ["0xCFCFCF", "0xCFCFCF"]
    ;如果今天没派遣过
    if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        stdTargetX := 1930
        stdTargetY := 1813
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [2199, 2055]
        stdCkptY := [1796, 1853]
        desiredColor := ["0x00ADFF", "0x00ADFF"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "全部派遣失败！"
                ExitApp
            }
            if UserCheckColor([1779], [1778], ["0xCFCFCF"], scrRatio)
                break
        }
        stdTargetX := 2073
        stdTargetY := 1818
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [2199, 2055]
        stdCkptY := [1796, 1853]
        desiredColor := ["0x00ADFF", "0x00ADFF"]
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "全部派遣失败！"
                ExitApp
            }
        }
    }
    ;回到大厅
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退出前哨基地失败！"
            ExitApp
        }
    }
}
;5: 好友点数收取
FriendPoint() {
    stdTargetX := 3729
    stdTargetY := 553
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入好友界面失败！"
            ExitApp
        }
    }
    stdCkptX := [2104, 2197]
    stdCkptY := [1825, 1838]
    desiredColor := ["0x0CAFF4", "0xF7FDFE"]
    stdTargetX := 2276
    stdTargetY := 1837
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) && !UserCheckColor([2104, 2054], [1825, 1876], [
        "0x8B8788", "0x8B8788"], scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入好友界面失败！"
            ExitApp
        }
    }
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "赠送好友点数失败"
            ExitApp
        }
    }
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退出好友界面失败！"
            ExitApp
        }
    }
}
;6: 模拟室5C
SimulationRoom() {
    stdTargetX := 2689
    stdTargetY := 1463
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    ;进入模拟室
    stdTargetX := 1547
    stdTargetY := 1138
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1829, 2024]
    stdCkptY := [1122, 1094]
    desiredColor := ["0xF8FCFD", "0xF8FCFD"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入模拟室失败！"
            ExitApp
        }
    }
    ;开始模拟
    stdTargetX := 1917
    stdTargetY := 1274
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2054, 2331]
    stdCkptY := [719, 746]
    desiredColor := ["0xF8FBFD", "0xF8FBFD"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入选关失败！"
            ExitApp
        }
    }
    ;选择5C
    stdTargetX := 2127
    stdTargetY := 1074
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    stdTargetX := 2263
    stdTargetY := 1307
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    ;点击开始模拟
    ;开始模拟
    stdTargetX := 2216
    stdTargetY := 1818
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1991]
    stdCkptY := [1814]
    desiredColor := ["0xFA801A"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "开始模拟失败！"
            ExitApp
        }
    }
    stdTargetX := 1903
    stdTargetY := 1369
    stdCkptX := [304]
    stdCkptY := [179]
    desiredColor := ["0x858289"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入buff选择页面失败！"
            ExitApp
        }
    }
    stdCkptX := [1760]
    yy := 2160
    stdCkptY := [yy]
    desiredColor := ["0xDFE1E1"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        yy := yy - 30
        stdCkptY := [yy]
        if A_Index > waitTolerance {
            ExitApp
        }
    }
    stdTargetX := 1760
    stdTargetY := yy
    stdCkptX := [2053]
    stdCkptY := [1933]
    desiredColor := ["0x2E77C1"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入战斗准备页面失败！"
            ExitApp
        }
    }
    ;点击进入战斗
    stdTargetX := 2225
    stdTargetY := 2004
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    stdCkptX := [1420, 2335]
    stdCkptY := [1243, 1440]
    desiredColor := ["0xFFFFFF", "0xFE0203"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        ;UserClick(stdTargetX, stdTargetY - 300, scrRatio)
        CheckAutoBattle()
        Sleep sleepTime
        if A_Index > waitTolerance * 2 {
            ;MsgBox "模拟室boss战异常！"
            break
        }
    }
    stdTargetX := 1898
    stdTargetY := 1996
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2115]
    stdCkptY := [1305]
    stdCkptX2 := [2115]
    stdCkptY2 := [1556]
    desiredColor := ["0xEFF3F5"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) && !UserCheckColor(stdCkptX2, stdCkptY2,
        desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "模拟室结束异常！"
            ExitApp
        }
    }
    if colorTolerance != 15 {
        Sleep 5000
    }
    ;点击模拟结束
    stdTargetX := 1923
    stdTargetY := 1276
    if UserCheckColor(stdCkptX2, stdCkptY2, desiredColor, scrRatio) {
        stdTargetX := 1923
        stdTargetY := 1552
    }
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    ;退回大厅
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
;7: 新人竞技场收菜
Arena() {
    ;进入方舟
    stdTargetX := 2689
    stdTargetY := 1463
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    ;收pjjc菜
    if sleepTime < 1500
        Sleep 1000
    stdTargetX := 2278
    stdTargetY := 1092
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    stdTargetX := 2129
    stdTargetY := 1920
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime // 2
}
;新人竞技场
RookieArena(times) {
    ;进入竞技场
    stdTargetX := 2208
    stdTargetY := 1359
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入竞技场失败！"
            ExitApp
        }
    }
    stdCkptX := [1683]
    stdCkptY := [606]
    desiredColor := ["0xF7FCFE"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入竞技场失败！"
            ExitApp
        }
    }
    ;进入新人竞技场
    stdTargetX := 1647
    stdTargetY := 1164
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [784]
    stdCkptY := [1201]
    desiredColor := ["0xF8FCFE"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > 5 {
            ;退回大厅
            stdTargetX := 333
            stdTargetY := 2041
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [64]
            stdCkptY := [470]
            desiredColor := ["0xFAA72C"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime
                if A_Index > waitTolerance {
                    MsgBox "退回大厅失败！"
                    ExitApp
                }
            }
            return
        }
        if A_Index > waitTolerance {
            MsgBox "进入新人竞技场失败！"
            ExitApp
        }
    }
    loop times {
        ;点击进入战斗
        stdTargetX := 2371
        stdTargetY := 1847
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [2700]
        stdCkptY := [1691]
        desiredColor := ["0xF7FCFE"]
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "选择对手失败！"
                ExitApp
            }
        }
        ;点击进入战斗
        stdTargetX := 2123
        stdTargetY := 1784
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [2784]
        stdCkptY := [1471]
        desiredColor := ["0xF8FCFD"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "新人竞技场作战失败！"
                ExitApp
            }
        }
    }
    ;退回大厅
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
;特殊竞技场
SpecialArena(times) {
}
;8: 对前n位nikke进行好感度咨询(可以通过收藏把想要咨询的nikke排到前面)
NotAllCollection() {
    stdCkptX := [2447]
    stdCkptY := [1464]
    desiredColor := ["0x444547"]
    return UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
}
LoveTalking(times) {
    ;进入妮姬列表
    stdTargetX := 1497
    stdTargetY := 2004
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入妮姬列表失败！"
            ExitApp
        }
    }
    stdCkptX := [1466, 1814]
    stdCkptY := [428, 433]
    desiredColor := ["0x3B3C3E", "0x3B3C3E"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入妮姬列表失败！"
            ExitApp
        }
    }
    ;进入咨询页面
    stdTargetX := 3308
    stdTargetY := 257
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1650]
    stdCkptY := [521]
    desiredColor := ["0x14B0F5"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        ;如果没次数了，直接退出
        if UserCheckColor(stdCkptX, stdCkptY, ["0xE0E0E2"], scrRatio) {
            stdTargetX := 333
            stdTargetY := 2041
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [64]
            stdCkptY := [470]
            desiredColor := ["0xFAA72C"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime
                if A_Index > waitTolerance {
                    MsgBox "退回大厅失败！"
                    ExitApp
                }
            }
            return
        }
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入咨询页面失败！"
            ExitApp
        }
    }
    ;点进第一个妮姬
    stdTargetX := 736
    stdTargetY := 749
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1504]
    stdCkptY := [1747]
    desiredColor := ["0xF99F22"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入妮姬咨询页面失败！"
            ExitApp
        }
    }
    loop times {
        stdCkptX := [1994]
        stdCkptY := [1634]
        desiredColor := ["0xFA6E34"]
        ;如果能够快速咨询
        if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) && !(g_settings["LongTalk"] && NotAllCollection()) {
            ;点击快速咨询
            stdTargetX := 2175
            stdTargetY := 1634
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [1994]
            stdCkptY := [1634]
            desiredColor := ["0xFA6E34"]
            while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime
                if A_Index > waitTolerance {
                    MsgBox "进入妮姬咨询页面失败！"
                    ExitApp
                }
            }
            ;点击确定
            stdTargetX := 2168
            stdTargetY := 1346
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            stdCkptX := [1504]
            stdCkptY := [1747]
            desiredColor := ["0xF99F22"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime
                if A_Index > waitTolerance {
                    MsgBox "快速咨询失败！"
                    ExitApp
                }
            }
        }
        else {
            ;如果不能快速咨询
            stdCkptX := [1982]
            stdCkptY := [1819]
            desiredColor := ["0x4A4A4C"]
            if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                stdTargetX := 2168
                stdTargetY := 1777
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime
                stdCkptX := [1504]
                stdCkptY := [1747]
                desiredColor := ["0xF99F22"]
                while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                    UserClick(stdTargetX, stdTargetY, scrRatio)
                    Sleep sleepTime
                    if A_Index > waitTolerance {
                        MsgBox "咨询失败！"
                        ExitApp
                    }
                }
                ;点击确认
                stdTargetX := 2192
                stdTargetY := 1349
                UserClick(stdTargetX, stdTargetY, scrRatio)
                Sleep sleepTime
                stdCkptX := [2109]
                stdCkptY := [1342]
                desiredColor := ["0x00A0EB"]
                while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                    UserClick(stdTargetX, stdTargetY, scrRatio)
                    Sleep sleepTime
                    if A_Index > waitTolerance {
                        MsgBox "咨询失败！"
                        ExitApp
                    }
                }
                stdCkptX := [1504]
                stdCkptY := [1747]
                desiredColor := ["0xF99F22"]
                stdTargetX := 1903
                stdTargetY := 1483
                while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                    if Mod(A_Index, 2) == 0
                        UserClick(stdTargetX, stdTargetY, scrRatio)
                    else
                        UserClick(stdTargetX, 1625, scrRatio)
                    Sleep sleepTime // 2
                    if A_Index > waitTolerance * 2 {
                        MsgBox "咨询失败！"
                        ExitApp
                    }
                }
            }
        }
        if A_Index >= times
            break
        ;翻页
        stdTargetX := 3778
        stdTargetY := 940
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [1982]
        stdCkptY := [1819]
        desiredColor := ["0x4A4A4C"]
        numOfTalked := A_Index
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index + numOfTalked >= times + 2
                break 2
            if A_Index > waitTolerance {
                MsgBox "咨询失败！"
                ExitApp
            }
        }
    }
    ;退回大厅
    stdTargetX := 333
    stdTargetY := 2041
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
;9: 爬塔一次(做每日任务)
FailTower() {
    stdTargetX := 2689
    stdTargetY := 1463
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    ;进入无限之塔
    stdTargetX := 2278
    stdTargetY := 776
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2405]
    stdCkptY := [1014]
    desiredColor := ["0xF8FBFE"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入无限之塔失败！"
            ExitApp
        }
    }
    stdTargetX := 1953
    stdTargetY := 934
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2129, 2305]
    stdCkptY := [1935, 1935]
    desiredColor := ["0x2E77C2", "0x2E77C2"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "选择作战失败！"
            ExitApp
        }
    }
    stdTargetX := 2242
    stdTargetY := 2001
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2129, 2305]
    stdCkptY := [1935, 1935]
    desiredColor := ["0x2E77C2", "0x2E77C2"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入作战失败！"
            ExitApp
        }
    }
    ;按esc
    stdCkptX := [2065]
    stdCkptY := [1954]
    desiredColor := ["0x238CFD"]
    stdTargetX := 3780
    stdTargetY := 75
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "按esc失败！"
            ExitApp
        }
    }
    ;按放弃战斗
    stdCkptX := [2065]
    stdCkptY := [1954]
    desiredColor := ["0x238CFD"]
    stdTargetX := 1678
    stdTargetY := 1986
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "放弃战斗失败！"
            ExitApp
        }
    }
    ;退回大厅
    stdTargetX := 301
    stdTargetY := 2030
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
MissionCompleted() {
    stdCkptX := [3451, 3756]
    stdCkptY := [2077, 2075]
    desiredColor := ["0x00A1FF", "0x00A1FF"]
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
        return true
    else
        return false
}
MissionFailed() {
    stdCkptX := [2306, 1920, 1590, 1560]
    stdCkptY := [702, 1485, 1489, 1473]
    desiredColor1 := ["0xB71013", "0xE9E9E7", "0x161515", "0xE9E9E7"]
    desiredColor2 := ["0xAD080B", "0xE9E9E7", "0x161515", "0xE9E9E7"]
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor1, scrRatio) or UserCheckColor(stdCkptX, stdCkptY, desiredColor2,
        scrRatio)
        return true
    else
        return false
}
MissionEnded() {
    stdCkptX := [3494, 3721, 3526, 3457, 3339, 3407]
    stdCkptY := [2086, 2093, 2033, 2043, 2040, 2043]
    desiredColor := ["0x6F6F6F", "0x6F6F6F", "0x030303", "0x434343", "0xE6E6E6", "0x000000"]
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
        return true
    else
        return false
}
;输出失败的企业塔
failedTower := Array()
CompanyTowerInfo() {
    info := ""
    loop failedTower.Length {
        info := info failedTower[A_Index] " "
    }
    if info != "" {
        info := "`n" info "已经爬不动惹dororo..."
    }
    return info
}
;10: 企业塔
CompanyTower() {
    stdTargetX := 2689
    stdTargetY := 1463
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    ;进入无限之塔
    stdTargetX := 2278
    stdTargetY := 776
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [2405]
    stdCkptY := [1014]
    desiredColor := ["0xF8FBFE"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入无限之塔失败！"
            ExitApp
        }
    }
    Sleep 1500
    ;尝试进入每座企业塔
    targX := [1501, 1779, 2061, 2332]
    targY := [1497, 1497, 1497, 1497]
    ckptX := [1383, 1665, 1935, 2222]
    ckptY := [1925, 1925, 1925, 1925]
    loop targX.Length {
        i := A_Index
        stdTargetX := targX[i]
        stdTargetY := targY[i]
        stdCkptX := [ckptX[i]]
        stdCkptY := [ckptY[i]]
        desiredColor := ["0x00AAF4"]
        ;如果未开放，则检查下一个企业
        if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
            continue
        ;点击进入企业塔
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "进入企业塔失败！"
                ExitApp
            }
        }
        ;直到成功进入企业塔
        stdCkptX := [3738]
        stdCkptY := [447]
        desiredColor := ["0xF8FCFE"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "进入企业塔失败！"
                ExitApp
            }
        }
        ;进入关卡页面
        stdTargetX := 1918
        stdTargetY := 919
        stdCkptX := [992]
        stdCkptY := [2011]
        desiredColor := ["0x000000"]
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "进入企业塔关卡页面失败！"
                ExitApp
            }
        }
        ;如果战斗次数已经用完
        Sleep 1000
        stdCkptX := [2038]
        stdCkptY := [2057]
        desiredColor := ["0x4D4E50"]
        if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            stdCkptX := [3738]
            stdCkptY := [447]
            desiredColor := ["0xF8FCFE"]
            while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                Send "{Escape}"
                Sleep sleepTime
            }
            stdCkptX := [2405]
            stdCkptY := [1014]
            desiredColor := ["0xF8FBFE"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
                Sleep sleepTime
            Sleep 1500
            continue
        }
        ;点击进入战斗
        stdTargetX := 2249
        stdTargetY := 1997
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        ;等待战斗结束
WaitForBattleEnd:
        while !(MissionCompleted() || MissionFailed() || MissionEnded()) {
            CheckAutoBattle()
            Sleep sleepTime
            if A_Index > waitTolerance * 20 {
                MsgBox "企业塔自动战斗失败！"
                ExitApp
            }
        }
        ;如果战斗失败或次数用完
        if MissionFailed() || MissionEnded() {
            if MissionFailed() {
                towerName := ""
                global failedTower
                switch i {
                    case 1:
                        towerName := "极乐净土塔"
                    case 2:
                        towerName := "米西利斯塔"
                    case 3:
                        towerName := "泰特拉塔"
                    case 4:
                        towerName := "朝圣者塔"
                    default:
                        towerName := ""
                }
                failedTower.Push towerName
            }
            Send "{Escape}"
            Sleep sleepTime
            while MissionFailed() || MissionEnded() {
                Send "{Escape}"
                Sleep sleepTime
            }
            stdCkptX := [3738]
            stdCkptY := [447]
            desiredColor := ["0xF8FCFE"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(3666, 1390, scrRatio)
                Sleep sleepTime
                if UserCheckColor([2088], [1327], ["0x00A0EB"], scrRatio) {
                    UserClick(2202, 1342, scrRatio)
                    Sleep sleepTime
                }
            }
            Sleep 5000
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                UserClick(3666, 1390, scrRatio)
                Sleep sleepTime
                if UserCheckColor([2088], [1327], ["0x00A0EB"], scrRatio) {
                    UserClick(2202, 1342, scrRatio)
                    Sleep sleepTime
                }
            }
            while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
                Send "{Escape}"
                Sleep sleepTime
            }
            stdCkptX := [2405]
            stdCkptY := [1014]
            desiredColor := ["0xF8FBFE"]
            while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio)
                Sleep sleepTime
            Sleep 1500
            continue
        }
        ;如果战斗胜利
        while MissionCompleted() {
            Send "t"
            Sleep sleepTime
        }
        goto WaitForBattleEnd
    }
    ;退回大厅
    stdTargetX := 301
    stdTargetY := 2030
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
;11: 进入异拦
Interception() {
    global g_numeric_settings ;
    stdTargetX := 2689
    stdTargetY := 1463
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime // 2
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入方舟失败！"
            ExitApp
        }
    }
    ;进入拦截战
    stdTargetX := 1781
    stdTargetY := 1719
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [1641]
    stdCkptY := [324]
    desiredColor := ["0x01D4F6"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入拦截战失败！"
            ExitApp
        }
    }
    stdTargetX := 559
    stdTargetY := 1571
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep 1000
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep 1000
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep 1000
    ;选择BOSS
    switch g_numeric_settings["InterceptionBoss"] {
        case 1:
            stdTargetX := 1556
            stdTargetY := 886
            stdCkptX := [1907]
            stdCkptY := [898]
            desiredColor := ["0xFA910E"]
        case 2:
            stdTargetX := 2279
            stdTargetY := 1296
            stdCkptX := [1923]
            stdCkptY := [908]
            desiredColor := ["0xFB01F1"]
        case 3:
            stdCkptX := [1917]
            stdCkptY := [910]
            desiredColor := ["0x037EF9"]
        case 4:
            stdTargetX := 2281
            stdTargetY := 899
            stdCkptX := [1916]
            stdCkptY := [907]
            desiredColor := ["0x00F556"]
        case 5:
            stdTargetX := 1551
            stdTargetY := 1299
            stdCkptX := [1919]
            stdCkptY := [890]
            desiredColor := ["0xFD000F"]
        default:
            MsgBox "BOSS选择错误！"
            ExitApp
    }
    stdTargetX := 1556
    stdTargetY := 886
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep 2000
        if A_Index > waitTolerance {
            MsgBox "选择BOSS失败！"
            ExitApp
        }
    }
    ;点击挑战按钮
    if UserCheckColor([1735], [1730], ["0x28282A"], scrRatio) {
        stdTargetX := 301
        stdTargetY := 2030
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        stdCkptX := [64]
        stdCkptY := [470]
        desiredColor := ["0xFAA72C"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "退回大厅失败！"
                ExitApp
            }
        }
        return
    }
    stdTargetX := 1924
    stdTargetY := 1779
    stdCkptX := [1390]
    stdCkptY := [1799]
    desiredColor := ["0x01AEF3"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "点击挑战失败！"
            ExitApp
        }
    }
    ;选择编队
    switch g_numeric_settings["InterceptionBoss"] {
        case 1:
            stdTargetX := 1882
            stdTargetY := 1460
            stdCkptX := [1843]
            stdCkptY := [1428]
        case 2:
            stdTargetX := 2020
            stdTargetY := 1460
            stdCkptX := [1981]
            stdCkptY := [1428]
        case 3:
            stdTargetX := 2151
            stdTargetY := 1460
            stdCkptX := [2113]
            stdCkptY := [1428]
        case 4:
            stdTargetX := 2282
            stdTargetY := 1460
            stdCkptX := [2248]
            stdCkptY := [1428]
        case 5:
            stdTargetX := 2421
            stdTargetY := 1460
            stdCkptX := [2380]
            stdCkptY := [1428]
        default:
            MsgBox "BOSS选择错误！"
            ExitApp
    }
    desiredColor := ["0x02ADF5"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep 1500
        if A_Index > waitTolerance {
            MsgBox "选择编队失败！"
            ExitApp
        }
    }
    ;如果不能快速战斗，就进入战斗
    stdCkptX := [1964]
    stdCkptY := [1800]
    desiredColor := ["0xF96B2F"]
    if !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        stdTargetX := 2219
        stdTargetY := 1992
        stdCkptX := [1962]
        stdCkptY := [1932]
        desiredColor := ["0xD52013"]
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "进入战斗失败！"
                ExitApp
            }
        }
        ;退出结算页面
        stdTargetX := 904
        stdTargetY := 1805
        stdCkptX := [3731, 3713, 3638]
        stdCkptY := [2040, 2034, 2091]
        desiredColor := ["0xE6E6E6", "0xE6E6E6", "0x000000"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            CheckAutoBattle()
            Sleep sleepTime
            if A_Index > waitTolerance * 20 {
                MsgBox "自动战斗失败！"
                ExitApp
            }
        }
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "退出结算页面失败！"
                ExitApp
            }
        }
    }
    ;检查是否退出
    stdCkptX := [1390]
    stdCkptY := [1799]
    desiredColor := ["0x01AEF3"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退出结算页面失败！"
            ExitApp
        }
    }
    ;快速战斗
    stdTargetX := 2229
    stdTargetY := 1842
    stdCkptX := [1964]
    stdCkptY := [1800]
    desiredColor := ["0xF96B2F"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "快速战斗失败！"
                ExitApp
            }
        }
        ;退出结算页面
        stdTargetX := 904
        stdTargetY := 1805
        stdCkptX := [2232, 2391, 2464]
        stdCkptY := [2100, 2099, 2051]
        desiredColor := ["0x000000", "0x000000", "0x000000"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "快速战斗结算失败！"
                ExitApp
            }
        }
        while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            UserClick(stdTargetX, stdTargetY, scrRatio)
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "退出结算页面失败！"
                ExitApp
            }
        }
        ;检查是否退出
        stdCkptX := [1390]
        stdCkptY := [1799]
        desiredColor := ["0x01AEF3"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
            Sleep sleepTime
            if A_Index > waitTolerance {
                MsgBox "退出结算页面失败！"
                ExitApp
            }
        }
        Sleep 1000
        stdTargetX := 2229
        stdTargetY := 1842
        stdCkptX := [1964]
        stdCkptY := [1800]
        desiredColor := ["0xF96B2F"]
    }
    ;退回大厅
    stdTargetX := 301
    stdTargetY := 2030
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退回大厅失败！"
            ExitApp
        }
    }
}
;11: 邮箱收取
Mail() {
    stdTargetX := 3667
    stdTargetY := 81
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;检测大厅点邮箱
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入邮箱失败！"
            ExitApp
        }
    }
    stdCkptX := [2085]
    stdCkptY := [1809]
    desiredColor := ["0xCAC7C4"] ;检测灰色的领取按钮
    stdTargetX := 2085
    stdTargetY := 1809
    ;Sleep sleepTime ;加载容错
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;不是灰色就一直点全部领取
        Sleep sleepTime
    }
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    stdTargetX := 2394
    stdTargetY := 291
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;确认领取+返回直到回到大厅
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退出邮箱失败！"
            ExitApp
        }
    }
}
;12: 任务收取
Mission() {
    stdTargetX := 3341
    stdTargetY := 206
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;检测大厅点任务
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入任务失败！"
            ExitApp
        }
    }
    stdTargetX := 2286
    stdTargetY := 1935
    x0 := 1512 ;用于遍历任务
    y0 := 395
    while UserCheckColor([1365, 2087], [1872, 1997], ["0xF5F5F5", "0xF5F5F5"], scrRatio) { ;检测是否在任务界面
        Sleep sleepTime
        UserClick(x0, y0, scrRatio) ;点任务标题
        Sleep sleepTime
        if !UserCheckColor([1365, 2087], [1872, 1997], ["0xF5F5F5", "0xF5F5F5"], scrRatio) { ;退出
            break
        }
        stdCkptX := [2276]
        stdCkptY := [1899]
        desiredColor := ["0x7B7C7B"]
        while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) { ;如果不是灰色就点
            Sleep sleepTime
            UserClick(stdTargetX, stdTargetY, scrRatio) ;点领取
        }
        x0 := x0 + 280 ;向右切换标题
    }
}
;13: 通行证收取 兼容双通行证 兼容特殊活动
Pass() {
    OnePass()
    stdCkptX := [3395]
    stdCkptY := [368]
    stdCkptY1 := [468] ;活动可能偏移
    desiredColor := ["0xFBFFFF"] ;白色的轮换按钮
    stdTargetX := 3395
    stdTargetY := 368
    stdTargetY1 := 468
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {  ;如果轮换按钮存在
        global PassRound
        PassRound := 0
        while (PassRound < 2) {
            userClick(stdTargetX, stdTargetY, scrRatio) ;转一下
            Sleep sleepTime
            PassRound := PassRound + 1
            stdCkptX := [3437]
            stdCkptY := [338]
            desiredColor := ["0xFE1809"] ;红点
            if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) { ;如果转出红点
                Sleep sleepTime
                userClick(stdTargetX, stdTargetY, scrRatio) ;再转一下
                Sleep sleepTime
                OnePass()
                break
            }
        }
    }
    if UserCheckColor(stdCkptX, stdCkptY1, desiredColor, scrRatio) {  ;检测是否偏移
        global PassRound
        PassRound := 0
        while (PassRound < 2) {
            userClick(stdTargetX, stdTargetY1, scrRatio) ;转一下
            Sleep sleepTime
            PassRound := PassRound + 1
            stdCkptX := [3437]
            stdCkptY := [438]
            desiredColor := ["0xFE1809"] ;红点
            if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) { ;如果转出红点
                Sleep sleepTime
                userClick(stdTargetX, stdTargetY1, scrRatio) ;再转一下
                Sleep sleepTime
                OnePass()
                break
            }
        }
    }
}
OnePass() { ;执行一次通行证
    stdTargetX := 3633
    stdTargetY := 405
    UserClick(stdTargetX, stdTargetY, scrRatio)
    Sleep sleepTime
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    while UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;检测大厅点通行证
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "进入通行证失败！"
            ExitApp
        }
    }
    stdCkptX := [1733]
    stdCkptY := [699]
    desiredColor := ["0xF1F5F6"]
    stdTargetX := 2130
    stdTargetY := 699
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) { ;左不是白则点右
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
    }
    stdCkptX := [1824]
    stdCkptY := [1992]
    desiredColor := ["0x7C7C7C"] ;检测灰色的全部领取
    stdTargetX := 1824
    stdTargetY := 1992
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;不是灰色就一直点领取
        Sleep sleepTime
    }
    stdCkptX := [2130]
    stdCkptY := [699]
    desiredColor := ["0xF1F5F6"]
    stdTargetX := 1733
    stdTargetY := 699
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) { ;右不是白则点左
        UserClick(stdTargetX, stdTargetY, scrRatio)
        Sleep sleepTime
    }
    stdCkptX := [1824]
    stdCkptY := [1992]
    desiredColor := ["0x7C7C7C"] ;检测灰色的全部领取
    stdTargetX := 1824
    stdTargetY := 1992
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;不是灰色就一直点领取
        Sleep sleepTime
    }
    stdCkptX := [64]
    stdCkptY := [470]
    desiredColor := ["0xFAA72C"]
    stdTargetX := 2418
    stdTargetY := 185
    while !UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
        UserClick(stdTargetX, stdTargetY, scrRatio) ;确认领取+返回直到回到大厅
        Sleep sleepTime
        if A_Index > waitTolerance {
            MsgBox "退出通行证失败！"
            ExitApp
        }
    }
    stdCkptX := [3395]
    stdCkptY := [368]
    desiredColor := ["0xFBFFFF"] ;检测是否多通行证
    stdTargetX := 3395
    stdTargetY := 368
    if UserCheckColor(stdCkptX, stdCkptY, desiredColor, scrRatio) {
    }
}
;通用塔
UniversalTower() {
}
; 通用函数，用于切换 g_settings Map 中的设置值
ToggleSetting(settingKey, guiCtrl, *) {
    global g_settings
    ; 切换值 (0 变 1, 1 变 0)
    g_settings[settingKey] := 1 - g_settings[settingKey]
    ; 可选: 如果需要，可以在这里添加日志记录
    ; ToolTip("切换 " settingKey " 为 " g_settings[settingKey])
}
ChangeOnNumOfBook(GUICtrl, *) {
    global g_numeric_settings
    g_numeric_settings["NumOfBook"] := GUICtrl.Value - 1
}
ChangeOnInterceptionBoss(GUICtrl, *) {
    global g_numeric_settings
    g_numeric_settings["InterceptionBoss"] := GUICtrl.Value
}
ChangeOnSleepTime(GUICtrl, *) {
    global sleepTime
    switch GUICtrl.Value {
        case 1: sleepTime := 750
        case 2: sleepTime := 1000
        case 3: sleepTime := 1250
        case 4: sleepTime := 1500
        case 5: sleepTime := 1750
        case 6: sleepTime := 2000
        default: sleepTime := 1500
    }
}
ChangeOnColorTolerance(GUICtrl, *) {
    global colorTolerance
    switch GUICtrl.Value {
        case 1: colorTolerance := 15
        case 2: colorTolerance := 35
        default: colorTolerance := 15
    }
}
ClickOnHelp(*) {
    msgbox "
    (
    #############################################
    使用说明
    对大多数老玩家来说Doro设置保持默认就好。
    万一Doro失控，请按Ctrl + 1组合键结束进程。
    万一Doro失控，请按Ctrl + 1组合键结束进程。
    万一Doro失控，请按Ctrl + 1组合键结束进程。
    ############################################# 
    要求：
    - 【设定-画质-全屏幕模式 + 16:9的显示器比例】（推荐）   或    【16:9的窗口模式（窗口尽量拉大，否则像素识别可能出现误差）】
    - 设定-画质-开启光晕效果
    - 设定-画质-开启颜色分级
    - 游戏语言设置为简体中文
    - 以**管理员身份**运行DoroHelper
    - 不要开启windows HDR显示
    ############################################# 
    步骤：
    -打开NIKKE启动器。点击启动。等右下角腾讯ACE反作弊系统扫完，NIKKE主程序中央SHIFT UP logo出现之后，再切出来点击“DORO!”按钮。如果你看到鼠标开始在左下角连点，那就代表启动成功了。然后就可以悠闲地去泡一杯咖啡，或者刷一会儿手机，等待Doro完成工作了。
    -也可以在游戏处在大厅界面时（有看板娘的页面）切出来点击“DORO!”按钮启动程序。
    -游戏需要更新的时候请更新完再使用Doro。
    ############################################# 
    其他:
    
    -检查是否发布了新版本。
    -如果出现死循环，提高点击间隔可以解决80%的问题。
    -如果你的电脑配置较好的话，或许可以尝试降低点击间隔。
    
    )"
}
ClickOnDoro(*) {
    WriteSettings()
    global g_settings, g_numeric_settings ;
    title := "勝利女神：妮姬"
    try {
        WinGetClientPos , , &userScreenW, &userScreenH, "勝利女神：妮姬"
    } catch as err {
        title := "ahk_exe nikke.exe"
    }
    numNikke := WinGetCount(title)
    if numNikke = 0 {
        MsgBox "未检测到NIKKE主程序"
        ExitApp
    }
    loop numNikke {
        nikkeID := WinGetIDLast(title)
        WinGetClientPos , , &userScreenW, &userScreenH, nikkeID
        global scrRatio
        scrRatio := userScreenW / stdScreenW
        ;nikkeID := WinWait(title)
        WinActivate nikkeID
        Login() ;登陆到主界面
        if g_settings["OutpostDefence"] ; 使用键名检查 Map
            OutpostDefence()
        if g_settings["CashShop"]
            CashShop()
        if g_settings["FreeShop"]
            FreeShop(g_numeric_settings["NumOfBook"])
        if g_settings["OutpostDefence"] ; 任务需要执行两次
            OutpostDefence()
        if g_settings["Expedition"]
            Expedition()
        if g_settings["FriendPoint"]
            FriendPoint()
        if g_settings["SimulationRoom"]
            SimulationRoom()
        if g_settings["Arena"] {
            Arena() ;收菜
            if g_settings["RookieArena"] ;新人竞技场
                RookieArena(g_numeric_settings["NumOfRookieBattle"])
            if g_settings["SpecialArena"] ;新人竞技场
                SpecialArena(g_numeric_settings["NumOfSpecialBattle"])
            else
                BackToHall()
        }
        if g_settings["LoveTalking"]
            LoveTalking(g_numeric_settings["NumOfLoveTalking"])
        if g_settings["FailTower"]
            FailTower()
        if g_settings["CompanyTower"]
            CompanyTower()
        if g_settings["Interception"]
            Interception()
        if g_settings["Mail"]
            Mail()
        if g_settings["Mission"]
            Mission()
        if g_settings["Pass"]
            Pass()
        if g_settings["UniversalTower"]
            UniversalTower()
    }
    if isBoughtTrash == 0
        MsgBox "协同作战商店似乎已经刷新了，快去看看吧"
    MsgBox "Doro完成任务！" CompanyTowerInfo()
    if g_settings["SelfClosing"]
        ExitApp
    Pause
}
SleepTimeToLabel(sleepTime) {
    return String(sleepTime / 250 - 2)
}
ColorToleranceToLabel(colorTolerance) {
    switch colorTolerance {
        case 15: return "1"
        case 35: return "2"
        default:
            return "1"
    }
}
IsCheckedToString(foo) {
    if foo
        return "Checked"
    else
        return ""
}
NumOfBookToLabel() {
    global g_numeric_settings
    return String(g_numeric_settings["NumOfBook"] + 1)
}
InterceptionBossToLabel() {
    global g_numeric_settings
    return String(g_numeric_settings["InterceptionBoss"])
}
WriteSettings(*) {
    global g_settings, g_numeric_settings, sleepTime, colorTolerance
    ; 从 g_settings Map 写入开关设置
    for key, value in g_settings {
        IniWrite(value, "settings.ini", "Toggles", key)
    }
    for key, value in g_numeric_settings {
        IniWrite(value, "settings.ini", "NumericSettings", key)
    }
    ; 写入其他独立设置
    IniWrite(sleepTime, "settings.ini", "Other", "sleepTime")
    IniWrite(colorTolerance, "settings.ini", "Other", "colorTolerance")
}
LoadSettings() {
    global g_settings, g_numeric_settings, sleepTime, colorTolerance
    default_settings := g_settings.Clone()
    ; 从 Map 加载开关设置
    for key, defaultValue in default_settings {
        readValue := IniRead("settings.ini", "Toggles", key, defaultValue)
        g_settings[key] := readValue
    }
    default_numeric_settings := g_numeric_settings.Clone() ; 保留一份默认数值设置
    for key, defaultValue in default_numeric_settings {
        readValue := IniRead("settings.ini", "NumericSettings", key, defaultValue)
        ; 确保读取的值是数字，如果不是则使用默认值
        if IsNumber(readValue) {
            g_numeric_settings[key] := Integer(readValue) ; 转换为整数
        } else {
            g_numeric_settings[key] := defaultValue
        }
    }
    ; 加载其他独立设置 (带默认值)
    sleepTime := IniRead("settings.ini", "Other", "sleepTime", 1500)
    colorTolerance := IniRead("settings.ini", "Other", "colorTolerance", 15)
}
SaveSettings(*) {
    WriteSettings()
    MsgBox "设置已保存！"
}
; 全局设置 Map 对象
global g_settings := Map(
    "OutpostDefence", 1,       ; 前哨基地防御
    "CashShop", 1,             ; 付费商店
    "FreeShop", 1,             ; 免费商店
    "Expedition", 1,           ; 派遣 (之前是 isCheckedExpedtion)
    "FriendPoint", 1,          ; 好友点数
    "Mail", 1,                 ; 邮箱
    "Mission", 1,              ; 任务
    "Pass", 1,                 ; 通行证
    "SimulationRoom", 1,       ; 模拟室
    "Arena", 1,                ; 竞技场收菜
    "RookieArena", 1,          ; 新人竞技场
    "SpecialArena", 1,         ; 特殊竞技场
    "LoveTalking", 1,          ; 咨询
    "CompanyWeapon", 0,        ; 企业武器熔炉 (商店)
    "Interception", 0,         ; 拦截战
    "CompanyTower", 1,         ; 企业塔
    "UniversalTower", 1,       ; 通用塔
    "FailTower", 0,            ; 每日爬塔任务
    "LongTalk", 1,             ; 详细咨询 (若图鉴未满)
    "AutoCheckUpdate", 0,      ; 自动检查更新
    "SelfClosing", 0,          ; 完成后自动关闭程序
    "BookFire", 0,             ; 手册：燃烧
    "BookWater", 0,            ; 手册：水冷
    "BookWind", 0,             ; 手册：风压
    "BookElec", 0,             ; 手册：电击
    "BookIron", 0,             ; 手册：铁甲
    ;"CheckBox",0              ; 简介个性化礼包
)
; 其他非简单开关的设置 Map 对象
global g_numeric_settings := Map(
    "NumOfBook", 3,               ; 购买手册数量
    "NumOfRookieBattle", 5,       ; 新人竞技场次数
    "NumOfSpecialBattle", 5,       ; 新人竞技场次数
    "NumOfLoveTalking", 10,       ; 咨询次数
    "InterceptionBoss", 1         ; 拦截战BOSS选择
)
global isBoughtTrash := 1         ; 检测废铁商店
;检测管理员身份
if !A_IsAdmin {
    MsgBox "请以管理员身份运行Doro"
    ExitApp
}
;读取设置
SetWorkingDir A_ScriptDir
try {
    LoadSettings()
}
catch as err {
    WriteSettings()
}
if g_settings["AutoCheckUpdate"] {
    CheckForUpdateHandler(false) ; 调用核心函数，标记为非手动检查
}
/**
 * 添加一个与 g_settings Map 关联的复选框到指定的 GUI 对象.
 * @param guiObj Gui - 要添加控件的 GUI 对象.
 * @param settingKey String - 在 g_settings Map 中对应的键名.
 * @param displayText String - 复选框旁边显示的文本标签.
 * @param options String - (可选) AutoHotkey GUI 布局选项字符串 (例如 "R1.2 xs+15").
 */
AddCheckboxSetting(guiObj, settingKey, displayText, options := "") {
    global g_settings, ToggleSetting ; 确保能访问全局 Map 和处理函数
    ; 检查 settingKey 是否存在于 g_settings 中
    if !g_settings.Has(settingKey) {
        MsgBox("错误: Setting key '" settingKey "' 在 g_settings 中未定义!", "添加控件错误", "IconX")
        return ; 或者抛出错误
    }
    ; 构建选项字符串，确保 Checked/空字符串 在选项之后，文本之前
    initialState := IsCheckedToString(g_settings[settingKey])
    fullOptions := options (options ? " " : "") initialState ; 如果有 options，加空格分隔
    ; 添加复选框控件，并将 displayText 作为第三个参数
    cbCtrl := guiObj.Add("Checkbox", fullOptions, displayText)
    ; 绑定 Click 事件，使用胖箭头函数捕获当前的 settingKey
    cbCtrl.OnEvent("Click", (guiCtrl, eventInfo) => ToggleSetting(settingKey, guiCtrl, eventInfo))
    ; 返回创建的控件对象 (可选，如果需要进一步操作)
    return cbCtrl
}
;创建gui
doroGui := Gui(, "Doro小帮手" currentVersion)
doroGui.Opt("+Resize")
doroGui.MarginY := Round(doroGui.MarginY * 0.9)
doroGui.SetFont("cred s12")
doroGui.Add("Text", "R1", "紧急停止按ctrl + 1 暂停按ctrl + 2")
doroGui.Add("Link", " R1", '<a href="https://github.com/kyokakawaii/DoroHelper">项目地址</a>')
doroGui.SetFont()
doroGui.Add("Button", "R1 x+10", "帮助").OnEvent("Click", ClickOnHelp)
doroGui.Add("Button", "R1 x+10", "检查更新").OnEvent("Click", ClickOnCheckForUpdate)
Tab := doroGui.Add("Tab3", "xm") ;由于autohotkey有bug只能这样写
Tab.Add(["设置", "收获", "商店", "日常", "默认"])
Tab.UseTab("设置")
AddCheckboxSetting(doroGui, "AutoCheckUpdate", "自动检查更新(确保能连上github)", "R1.2")
AddCheckboxSetting(doroGui, "SelfClosing", "任务完成后自动关闭程序", "R1.2")
doroGui.Add("Text", , "点击间隔(单位毫秒)，谨慎更改")
doroGui.Add("DropDownList", "Choose" SleepTimeToLabel(sleepTime), [750, 1000, 1250, 1500, 1750, 2000]).OnEvent("Change",
    ChangeOnSleepTime)
doroGui.Add("Text", , "色差容忍度，能跑就别改")
doroGui.Add("DropDownList", "Choose" ColorToleranceToLabel(colorTolerance), ["严格", "宽松"]).OnEvent("Change",
    ChangeOnColorTolerance)
doroGui.Add("Button", "R1", "保存当前设置").OnEvent("Click", SaveSettings)
Tab.UseTab("收获")
AddCheckboxSetting(doroGui, "OutpostDefence", "领取前哨基地防御奖励+1次免费歼灭", "R1.2")
AddCheckboxSetting(doroGui, "CashShop", "领取付费商店免费钻(进不了商店的别选)", "R1.2")
AddCheckboxSetting(doroGui, "Expedition", "派遣委托", "R1.2")
AddCheckboxSetting(doroGui, "FriendPoint", "好友点数收取", "R1.2")
AddCheckboxSetting(doroGui, "Mail", "邮箱收取", "R1.2")
AddCheckboxSetting(doroGui, "Mission", "任务收取", "R1.2")
AddCheckboxSetting(doroGui, "Pass", "通行证收取", "R1.2")
Tab.UseTab("商店")
doroGui.Add("Text", "R1.2 Section", "普通商店")
AddCheckboxSetting(doroGui, "FreeShop", "每日白嫖2次", "R1.2 xs+15")
doroGui.Add("Text", " R1.2 xs+15", "❌购买简介个性化礼包")
doroGui.Add("Text", "R1.2 xs", "竞技场商店")
doroGui.Add("Text", "R1.2 xs+15", "购买手册：")
AddCheckboxSetting(doroGui, "BookFire", "燃烧", "R1.2 xs+15")
AddCheckboxSetting(doroGui, "BookWater", "水冷", "R1.2 X+1")
AddCheckboxSetting(doroGui, "BookWind", "风压", "R1.2 X+1")
AddCheckboxSetting(doroGui, "BookElec", "电击", "R1.2 X+1")
AddCheckboxSetting(doroGui, "BookIron", "铁甲", "R1.2 X+1")
AddCheckboxSetting(doroGui, "CompanyWeapon", "购买公司武器熔炉", "R1.2 xs+15")
doroGui.Add("Text", " R1.2 xs+15", "❌购买简介个性化礼包")
doroGui.Add("Text", "R1.2 xs Section", "废铁商店")
doroGui.Add("Text", " R1.2 xs+15", "❌购买珠宝")
doroGui.Add("Text", " R1.2 xs+15", "购买好感券：")
doroGui.Add("Text", " R1.2 xs+15", "❌通用")
doroGui.Add("Text", " R1.2 x+1", "❌朝圣者")
doroGui.Add("Text", " R1.2 x+1", "❌反常")
doroGui.Add("Text", " R1.2 xs+15", "❌极乐净土")
doroGui.Add("Text", " R1.2 x+1", "❌米西利斯")
doroGui.Add("Text", " R1.2 x+1", "❌泰特拉")
doroGui.Add("Text", " R1.2 xs+15", "购买资源")
doroGui.Add("Text", " R1.2 xs+15", "❌信用点+盒")
doroGui.Add("Text", " R1.2 x+1", "❌战斗数据辑盒")
doroGui.Add("Text", " R1.2 x+1", "❌芯尘盒")
Tab.UseTab("日常")
AddCheckboxSetting(doroGui, "SimulationRoom", "模拟室5C(普通关卡需要快速战斗)", "R1.2")
AddCheckboxSetting(doroGui, "Arena", "竞技场收菜", "R1.2 Section")
AddCheckboxSetting(doroGui, "RookieArena", "新人竞技场(请点开快速战斗)", "R1.2 XP+15 Y+M")
AddCheckboxSetting(doroGui, "SpecialArena", "特殊竞技场(请点开快速战斗)", "R1.2 Y+M")
AddCheckboxSetting(doroGui, "LoveTalking", "咨询妮姬(可以通过收藏改变妮姬排序)", "R1.2 xs Section") ; 注意 Section 选项用法（保存此控件位置并定义一个新控件段）
AddCheckboxSetting(doroGui, "FailTower", "爬塔摆烂一次（用于完成每日任务）", "R1.2")
AddCheckboxSetting(doroGui, "CompanyTower", "尽可能地爬企业塔", "R1.2 xs Section")
AddCheckboxSetting(doroGui, "Interception", "使用对应编队进行异常拦截自动战斗", "R1.2 xs")
doroGui.Add("DropDownList", "Choose" InterceptionBossToLabel(), ["克拉肯(石)，编队1", "过激派(头)，编队2", "镜像容器(手)，编队3",
    "茵迪维利亚(衣)，编队4", "死神(脚)，编队5"]).OnEvent("Change", ChangeOnInterceptionBoss)
AddCheckboxSetting(doroGui, "UniversalTower", "尽可能地爬通用塔", "R1.2")
Tab.UseTab("默认")
doroGui.Add("Text", , "购买代码手册数量")
doroGui.Add("DropDownList", "Choose" NumOfBookToLabel(), [0, 1, 2, 3]).OnEvent("Change", ChangeOnNumOfBook)
Tab.UseTab()
doroGui.Add("Button", "Default w80 xm+100", "DORO!").OnEvent("Click", ClickOnDoro)
doroGui.Show()
^1:: {
    ExitApp
}
^2:: {
    Pause -1
}
