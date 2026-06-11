object TELEFONHTTPSRUTINOK: TTELEFONHTTPSRUTINOK
  Left = 202
  Top = 129
  BorderStyle = bsNone
  Caption = 'TELEFONHTTPSRUTINOK'
  ClientHeight = 121
  ClientWidth = 623
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 64
    Top = 32
    Width = 460
    Height = 22
    Caption = 'AZ ADATOKAT ELK'#220'LDTEM A SZOLG'#193'LTAT'#211'HOZ'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 40
    Top = 64
    Width = 494
    Height = 41
    Caption = 'V'#193'ROK A VISSZAIGAZOL'#193'SRA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object LISTABOX: TListBox
    Left = 144
    Top = -96
    Width = 353
    Height = 121
    Color = 10551295
    ItemHeight = 13
    TabOrder = 0
  end
  object FAKLYA: TAnimate
    Left = 544
    Top = 32
    Width = 80
    Height = 50
    Active = False
    CommonAVI = aviFindFolder
    StopFrame = 29
  end
  object IdHTTP1: TIdHTTP
    Intercept = SSL
    Port = 443
    Request.Accept = 'text/html, */*'
    Request.ContentLength = 0
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ProxyPort = 0
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Left = 8
    Top = 8
  end
  object SSL: TIdConnectionInterceptOpenSSL
    SSLOptions.Method = sslvSSLv23
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    OnGetPassword = SSLGetPassword
    Left = 40
    Top = 8
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 100
    Left = 72
    Top = 8
  end
  object REPLYTIMER: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = REPLYTIMERTimer
    Left = 8
    Top = 40
  end
  object TESTTOPUPTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = TESTTOPUPTIMERTimer
    Left = 8
    Top = 88
  end
  object LIVETOPUPTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = LIVETOPUPTIMERTimer
    Left = 40
    Top = 88
  end
  object CANCELTOPUPTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = CANCELTOPUPTIMERTimer
    Left = 72
    Top = 88
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTIMERTimer
    Left = 104
    Top = 8
  end
end
