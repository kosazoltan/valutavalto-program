object MATRICAHTTPSRUTINOK: TMATRICAHTTPSRUTINOK
  Left = 136
  Top = 205
  BorderStyle = bsNone
  Caption = 'MATRICAHTTPSRUTINOK'
  ClientHeight = 82
  ClientWidth = 857
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clYellow
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = -40
    Width = 857
    Height = 121
    Caption = 'A K'#201'RELEM TOV'#193'BBIT'#193'SA A SZOLG'#193'LTAT'#211'HOZ'
    Color = 11599792
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    object LISTABOX: TListBox
      Left = 24
      Top = 8
      Width = 121
      Height = 105
      ItemHeight = 33
      TabOrder = 0
    end
    object FAKLYA: TAnimate
      Left = 768
      Top = 48
      Width = 80
      Height = 50
      Active = False
      CommonAVI = aviFindFolder
      StopFrame = 29
    end
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 2500
    OnTimer = KILEPOTimerTimer
    Left = 40
    Top = 8
  end
  object IdHTTP1: TIdHTTP
    Intercept = SSL
    Request.Accept = 'text/html, */*'
    Request.ContentLength = 0
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ProxyPort = 0
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Left = 184
    Top = 8
  end
  object SSL: TIdConnectionInterceptOpenSSL
    SSLOptions.Method = sslvSSLv3
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    OnGetPassword = SSLGetPassword
    Left = 216
    Top = 8
  end
  object REPLYTIMER: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = REPLYTIMERTimer
    Left = 280
    Top = 8
  end
  object TESTAAKTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = TESTAAKTIMERTimer
    Left = 160
    Top = 48
  end
  object LIVEAAKTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = LIVEAAKTIMERTimer
    Left = 192
    Top = 48
  end
  object CANCELAAKTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = CANCELAAKTIMERTimer
    Left = 224
    Top = 48
  end
end
