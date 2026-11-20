# BAS Hub Loader System

Sistem loader ala WisHub / Speed Hub X:

```text
Execute loader.lua
-> loader cek PlaceId
-> cocokkan ke tabel Games
-> load file game dari GitHub raw
-> script game jalan
```

## Struktur

```text
loader-system/
  loader.lua
  games/
    break_and_steal_egg.lua
```

`games/break_and_steal_egg.lua` = v4 kita: Speed Hub X UI + AutoBreak + Speed.

## Cara pasang di GitHub

1. Bikin repo GitHub baru, public, nama bebas. Contoh: `bas-hub`.
2. Upload `loader.lua` dan folder `games/` ke repo itu.
3. `BASE_URL` di `loader.lua` sudah diset ke repo ini:

```lua
local BASE_URL = "https://raw.githubusercontent.com/lamsoxee/bas-hub/main/games/"
```

4. Execute di Delta pakai loadstring loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/lamsoxee/bas-hub/main/loader.lua"))()
```

## Nambah game baru

1. Taruh file script game di `games/`, contoh `steal_a_egg.lua`.
2. Tambah entry di tabel `Games` di `loader.lua`:

```lua
["Steal a Egg"] = {
    Places = { "107778070777162" },
    File = "steal_a_egg.lua",
    Keyed = false,
},
```

3. Push ke GitHub. Loader yang sama langsung bisa load game baru itu.

## Key system

Sekarang semua game `Keyed = false`, jadi langsung jalan tanpa key.

Kalau nanti mau pakai key:

- Set game jadi `Keyed = true`.
- Isi `KEYSYSTEM_URL` di `loader.lua`.
- Loader akan cek `bas_script_key` / `script_key` di env dulu, baru buka key gate.

## Catatan

- Repo harus public, atau raw URL-nya tidak bisa diambil dari dalam game.
- Kalau update script game, cukup update file di `games/` lalu push. User yang execute loader akan dapat versi terbaru.
- Kalau GitHub raw lambat update, tunggu beberapa menit atau ganti nama file versi baru.
