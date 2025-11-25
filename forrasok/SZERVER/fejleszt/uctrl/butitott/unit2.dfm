object GETIDOSZAK: TGETIDOSZAK
  Left = 194
  Top = 125
  BorderStyle = bsNone
  Caption = 'GETIDOSZAK'
  ClientHeight = 221
  ClientWidth = 572
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
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 569
    Height = 217
    Color = clWhite
    TabOrder = 0
    object Shape1: TShape
      Left = 1
      Top = 1
      Width = 567
      Height = 215
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label3: TLabel
      Left = 144
      Top = 24
      Width = 308
      Height = 24
      Caption = 'K'#201'REM A KIV'#193'NT ID'#336'SZAKOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 356
      Top = 84
      Width = 46
      Height = 22
      Caption = '-T'#211'L'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 476
      Top = 84
      Width = 26
      Height = 22
      Caption = '-IG'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object IDSZRENDBEN: TBitBtn
      Left = 104
      Top = 152
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'ID'#336'SZAK RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IDSZRENDBENClick
    end
    object IDSZMEGSEM: TBitBtn
      Left = 288
      Top = 152
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = IDSZMEGSEMClick
    end
    object EVCOMBO: TComboBox
      Left = 72
      Top = 80
      Width = 81
      Height = 30
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 2
      Text = '2019'
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 152
      Top = 80
      Width = 145
      Height = 31
      DropDownCount = 12
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 23
      ParentFont = False
      TabOrder = 3
      Text = 'HOCOMBO'
      OnChange = EVCOMBOChange
    end
    object TOLCOMBO: TComboBox
      Left = 296
      Top = 80
      Width = 58
      Height = 30
      DropDownCount = 17
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 4
      Text = 'TOLCOMBO'
      OnChange = TOLCOMBOChange
    end
    object IGCOMBO: TComboBox
      Left = 416
      Top = 80
      Width = 58
      Height = 30
      DropDownCount = 17
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 5
      Text = 'IGCOMBO'
      OnChange = IGCOMBOChange
    end
  end
end
