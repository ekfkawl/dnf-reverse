object _: T_
  Left = 0
  Top = 0
  ClientHeight = 276
  ClientWidth = 487
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object CheckBox1: TCheckBox
    Left = 32
    Top = 24
    Width = 97
    Height = 17
    Caption = 'quick key'
    Checked = True
    State = cbChecked
    TabOrder = 0
    OnClick = CheckBox1Click
  end
  object CheckBox2: TCheckBox
    Left = 32
    Top = 56
    Width = 97
    Height = 17
    Caption = 'auto dash'
    Checked = True
    State = cbChecked
    TabOrder = 1
    OnClick = CheckBox2Click
  end
end
