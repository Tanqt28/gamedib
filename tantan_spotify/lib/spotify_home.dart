import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song.dart';

class SpotifyHome extends StatefulWidget {
  const SpotifyHome({super.key});
  @override State<SpotifyHome> createState() => _SpotifyHomeState();
}

class _SpotifyHomeState extends State<SpotifyHome> {
  final AudioPlayer _p = AudioPlayer();
  Content? _curr;

  @override
  void initState() {
    super.initState();
    _p.playerStateStream.listen((s) => s.processingState == ProcessingState.completed ? _next() : null);
  }

  void _play(Content s) async {
    if (_curr?.id == s.id) {
      _p.playing ? await _p.pause() : await _p.play();
    } else {
      setState(() => _curr = s);
      await _p.setAudioSource(s.audioUrl.startsWith('http') ? AudioSource.uri(Uri.parse(s.audioUrl)) : AudioSource.asset(s.audioUrl));
      await _p.play();
    }
    setState(() {});
  }

  void _next() => _play(mockSongs[(mockSongs.indexWhere((s) => s.id == _curr?.id) + 1) % mockSongs.length]);

  @override void dispose() { _p.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Column(children: [
      Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        const Icon(Icons.library_music, color: Colors.green), const SizedBox(width: 10),
        const Text('Spotitan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const Spacer(), const Icon(Icons.search, color: Colors.grey), const SizedBox(width: 20), const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 18))
      ])),
      Expanded(child: Row(children: [
        Container(width: 200, color: Colors.white.withValues(alpha: 0.05), child: Column(children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('LIBRARY', style: TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(child: ListView(children: mockSongs.map((s) => ListTile(onTap: () => _play(s), title: Text(s.title, style: const TextStyle(fontSize: 13, color: Colors.white), overflow: TextOverflow.ellipsis), dense: true)).toList())),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network('https://picsum.photos/400', width: 160, height: 160, fit: BoxFit.cover)),
            const SizedBox(width: 24),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PLAYLIST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Spotitan', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -2, color: Colors.white)),
              Text('kai • OPM Hits • 2024', style: TextStyle(color: Colors.white70)),
            ])),
          ]),
          const SizedBox(height: 32),
          ...mockSongs.map((s) => ListTile(onTap: () => _play(s), leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(s.imageUrl, width: 40, height: 40, fit: BoxFit.cover)),
            title: Text(s.title, style: TextStyle(color: _curr?.id == s.id ? Colors.green : Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(s.artist, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Text(s.duration, style: const TextStyle(color: Colors.grey, fontSize: 12)), dense: true,
          )),
        ]))
      ])),
      if (_curr != null) Container(height: 90, decoration: const BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.white12))), padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Expanded(flex: 2, child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(_curr!.imageUrl, width: 50, height: 50, fit: BoxFit.cover)), const SizedBox(width: 12),
          Flexible(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_curr!.title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(_curr!.artist, style: const TextStyle(color: Colors.grey, fontSize: 11))])),
        ])),
        Expanded(flex: 3, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () {}),
            IconButton(icon: Icon(_p.playing ? Icons.pause_circle : Icons.play_circle, size: 40, color: Colors.white), onPressed: () => _play(_curr!)),
            IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: _next),
          ]),
          StreamBuilder<Duration>(stream: _p.positionStream, builder: (c, snapshot) => SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4)), 
            child: Slider(value: (snapshot.data?.inSeconds ?? 0).toDouble().clamp(0, (_p.duration?.inSeconds ?? 1).toDouble()), max: (_p.duration?.inSeconds ?? 1).toDouble(), onChanged: (v) => _p.seek(Duration(seconds: v.toInt())), activeColor: Colors.white, inactiveColor: Colors.white24))),
        ])),
        const Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Icon(Icons.volume_up, size: 20, color: Colors.grey))),
      ]))
    ]),
  );
}
