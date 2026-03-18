# 11 — Audio Codec (SSM2603) — On Hold

Configures the Zybo's SSM2603 audio codec via PS I2C, then plays a
continuous 750 Hz sine tone through the headphone jack. The tone is
generated entirely in the PL by an I2S transmitter (`i2s_tone_gen.v`)
that outputs a pre-computed 16-bit sine LUT at 48 kHz sample rate.

**Teaches:** I2C codec initialization, I2S protocol (BCLK/LRCLK/SDATA),
PL audio clocking (MCLK from PS FCLK), PS↔PL clock coordination.

**Status:** On hold — codec initialization sequence verified; headphone
output testing pending.

## Build and Run
```
./scripts/build_hw.sh 11_audio
./scripts/build_sw.sh 11_audio
./scripts/deploy.sh 11_audio
```

## What to Expect
- Serial console prints I2C register write status.
- Plug headphones into HP jack — 750 Hz tone should play.

## Source
- `src/11_audio/hw/i2s_tone_gen.v`
- `src/11_audio/sw/audio_demo.c`
