enum ContentType { song, podcast }

class Content {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String imageUrl;
  final String audioUrl;
  final ContentType type;

  Content({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.imageUrl,
    required this.audioUrl,
    this.type = ContentType.song,
  });
}

// Strictly unique audio sources to fix the "wrong song" issue.
// Each OPM title now points to a unique SoundHelix track ID.
final List<Content> mockSongs = [
  Content(
    id: "s1", 
    title: "Pasilyo", 
    artist: "Sunkissed Lola",
    album: "Pasilyo - Single",
    duration: "4:30",
    imageUrl: "https://picsum.photos/400/400?random=11", 
    audioUrl: "lib/music/SunKissed Lola - Pasilyo (Official Lyric Video) [XToA-1dZYWA].mp3"
  ),
  Content(
    id: "s2", 
    title: "Uhaw",
    artist: "Dilaw",
    album: "Sansinukob",
    duration: "4:01",
    imageUrl: "https://picsum.photos/400/400?random=12",
    audioUrl: "lib/music/@Dilaw - Uhaw (Tayong Lahat) (Lyrics) [c1cRRSozPMw].mp3"
  ),
  Content(
    id: "s3", 
    title: "Raining in Manila",
    artist: "Lola Amour",
    album: "Raining in Manila",
    duration: "4:50",
    imageUrl: "https://picsum.photos/400/400?random=13",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"
  ),
  Content(
    id: "s4", 
    title: "Gento",
    artist: "SB19",
    album: "PAGTATAG!",
    duration: "3:45",
    imageUrl: "https://picsum.photos/400/400?random=14",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"
  ),
  Content(
    id: "s5", 
    title: "Kathang Isip",
    artist: "Ben&Ben",
    album: "Limasawa Street",
    duration: "5:18",
    imageUrl: "https://picsum.photos/400/400?random=15",
    audioUrl: "lib/music/Kathang Isip [sKa8HtWgOxk].mp3"
  ),
  Content(
    id: "s6", 
    title: "Leaves",
    artist: "Ben&Ben",
    album: "Limasawa Street",
    duration: "5:10",
    imageUrl: "https://picsum.photos/400/400?random=16",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3"
  ),
  Content(
    id: "s7",
    title: "Mahika",
    artist: "Adie, Janine",
    album: "Mahika - Single",
    duration: "3:40",
    imageUrl: "https://picsum.photos/400/400?random=17",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3"
  ),
  Content(
    id: "s8",
    title: "Paraluman",
    artist: "Adie",
    album: "Paraluman",
    duration: "5:12",
    imageUrl: "https://picsum.photos/400/400?random=18",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3"
  ),
  Content(
    id: "s9",
    title: "Binibini",
    artist: "Zack Tabudlo",
    album: "Episode",
    duration: "3:41",
    imageUrl: "https://picsum.photos/400/400?random=19",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3"
  ),
  Content(
    id: "s10",
    title: "Pano",
    artist: "Zack Tabudlo",
    album: "Pano - Single",
    duration: "4:14",
    imageUrl: "https://picsum.photos/400/400?random=20",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3"
  ),
];

final List<Content> mockPodcasts = [
  Content(
    id: "p1", 
    title: "The Morning Rush",
    artist: "RX 93.1",
    album: "Daily Morning",
    duration: "45:00",
    imageUrl: "https://picsum.photos/400/400?random=30", 
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3",
    type: ContentType.podcast
  ),
  Content(
    id: "p2",
    title: "Skypodcast",
    artist: "Kryz & Slater",
    album: "Sky Talks",
    duration: "32:00",
    imageUrl: "https://picsum.photos/400/400?random=31",
    audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3",
    type: ContentType.podcast
  ),
];
