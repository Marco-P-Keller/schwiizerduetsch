#!/usr/bin/env python3
"""Generate one audio file per phrase with ElevenLabs and drop them into Schwiizerduetsch/Audio.

  export ELEVENLABS_API_KEY=...
  export VOICE_ID=<a Swiss German voice from the ElevenLabs Voice Library>
  python3 scripts/generate_audio.py

Listen to every file afterwards – no TTS is perfect for dialect; re-record bad ones with a native speaker.
"""
import json, os, re, sys, urllib.request

KEY, VOICE = os.environ.get("ELEVENLABS_API_KEY"), os.environ.get("VOICE_ID")
if not KEY or not VOICE:
    sys.exit("Set ELEVENLABS_API_KEY and VOICE_ID")
src = open("Schwiizerduetsch/Models/ContentData.swift", encoding="utf-8").read()
out = "Schwiizerduetsch/Audio"
os.makedirs(out, exist_ok=True)
for unit in re.finditer(r'unit\("([a-z]+)".*?\{ b in(.*?)\n            \},', src, re.S):
    uid, body = unit.group(1), unit.group(2)
    for i, m in enumerate(re.finditer(r'b\.add\("((?:[^"\\]|\\.)*)"', body), 1):
        text, path = m.group(1).replace('\\"', '"'), f"{out}/{uid}-{i}.mp3"
        if os.path.exists(path):
            continue
        req = urllib.request.Request(
            f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE}?output_format=mp3_44100_64",
            data=json.dumps({"text": text, "model_id": "eleven_multilingual_v2",
                             "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}}).encode(),
            headers={"xi-api-key": KEY, "Content-Type": "application/json"})
        open(path, "wb").write(urllib.request.urlopen(req).read())
        print("ok", path, text)
