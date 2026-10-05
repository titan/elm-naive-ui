# BRIEF — Live.Controls (Button, Input, InputNumber, Switch, Checkbox, Radio, Rate, Slider, InputOtp)

Read `tasks/brief-live-common.md` FIRST — it defines the contract, rules, verify and
commit steps. This brief only lists YOUR demos.

FILE: `examples/src/Live/Controls.elm` (replace the stub). subscriptions = Sub.none.

Read first: `src/NUI/Button.elm`, `src/NUI/Input.elm`, `src/NUI/InputNumber.elm`,
`src/NUI/Switch.elm`, `src/NUI/Checkbox.elm`, `src/NUI/Radio.elm`, `src/NUI/Rate.elm`,
`src/NUI/Slider.elm`, `src/NUI/InputOtp.elm` (headers + Options + any exposed helpers).

DEMOS (each a demoRow; make every one genuinely interactive):
1. **Button · press counter** — one Primary button with `onPress` (channel: onPress),
   label shows the count; a secondary "reset" button.
2. **Input · controlled + clear** — Input with `onInput`/`onFocus`/`onBlur`; show the
   live value + focus state as a caption line under it (Element.text). If Input exposes
   the clear channel (see BaseSelection-derived options), wire clearing. Pair mode too
   if `Input.pairValue`/`onPairInput` is feasible — a date-range-like two-field demo.
3. **InputNumber · stepper** — InputNumber with its value channel(s) (read Options;
   there are update-value and possibly step buttons msgs). Show current value.
4. **Switch · toggle** — Switch wired both ways (value in model, channel flips it).
5. **Checkbox · group + indeterminate** — a small checkbox list (3 items) with a
   check-all master that goes indeterminate when some are checked (Checkbox exposes
   indeterminate rendering; compute it in your model).
6. **Radio.Group · pick one** — Radio.Group over 3 options, selected shown.
7. **Rate · hover + commit** — Rate with hover/preview + commit channels; caption
   shows hovered vs committed value.
8. **Slider · range** — Slider wired (single value; if the port supports a range mode
   per its Options, add that too). Caption shows the value(s).
9. **InputOtp · complete** — InputOtp with its completion channel; when complete,
   show the joined code below.
