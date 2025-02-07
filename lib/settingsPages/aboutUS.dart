import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  List<TeamMember> teamMembers = [];

  @override
  void initState() {
    super.initState();
    _initializeTeamMembers();
  }

  void _initializeTeamMembers() {
    teamMembers = [
      TeamMember(
        name: "Gojo Singh",
        title: "Founder",
        quote: "\"Tuesday, Thursday chod ke daily chicken.\"",
        skills: "Non-Vegetarian,Rajput",
        imageUrl: "https://w0.peakpx.com/wallpaper/666/961/HD-wallpaper-anime-jujutsu-kaisen-satoru-gojo.jpg",
        videoUrl: "https://evil-bane.github.io/SRM-one-CDN/videoplayback%20(1).mp4",
      ),
      TeamMember(
        name: "Sukuna Awasthi",
        title: "Web Developer",
        quote: "\"Bas anda khata hu\"",
        skills: "Veg,Jati-Vadi Brahmin",
        imageUrl: "https://i.pinimg.com/736x/87/8a/d2/878ad20c056c7629c870c63f0c13bd70.jpg",
        videoUrl: "https://evil-bane.github.io/SRM-one-CDN/y2mate.com%20-%20Jujutsu%20Kaisen%20EditAMV%20Red%20Sex%20Sukuna_1080.mp4",
      ),
      TeamMember(
        name: "ChatGPT X DeepSeek",
        title: "Top Contributer",
        quote: "\"Pura code mene likha h.\"",
        skills: "Coder",
        imageUrl: "https://c4.wallpaperflare.com/wallpaper/314/369/167/ultron-4k-hd-wallpaper-preview.jpg",
        videoUrl: "https://evil-bane.github.io/SRM-one-CDN/gpt.mp4",
      ),
    ];
  }

  void _handlePageChange(int index) {
    setState(() {
      _currentPage = index;
    });
    // Pause all other videos
    for (int i = 0; i < teamMembers.length; i++) {
      if (i != index && teamMembers[i].controller?.value.isPlaying == true) {
        teamMembers[i].controller?.pause();
      }
    }
    // Play current video if initialized
    if (teamMembers[index].controller?.value.isInitialized == true) {
      teamMembers[index].controller?.play();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var member in teamMembers) {
      member.controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(color: Colors.black),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    "About Us",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: teamMembers.length,
                    onPageChanged: _handlePageChange,
                    itemBuilder: (context, index) {
                      return TeamMemberCard(
                        member: teamMembers[index],
                        isActive: _currentPage == index,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeamMember {
  final String name;
  final String title;
  final String quote;
  final String skills;
  final String imageUrl;
  final String videoUrl;
  VideoPlayerController? controller;

  TeamMember({
    required this.name,
    required this.title,
    required this.quote,
    required this.skills,
    required this.imageUrl,
    required this.videoUrl,
  });
}

class TeamMemberCard extends StatefulWidget {
  final TeamMember member;
  final bool isActive;

  const TeamMemberCard({
    Key? key,
    required this.member,
    required this.isActive,
  }) : super(key: key);

  @override
  State<TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<TeamMemberCard> {
  bool _isMuted = true;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    widget.member.controller ??= VideoPlayerController.networkUrl(
      Uri.parse(widget.member.videoUrl),
    );

    try {
      await widget.member.controller!.initialize();
      widget.member.controller!.setLooping(true);
      widget.member.controller!.setVolume(_isMuted ? 0 : 1);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          if (widget.isActive) {
            widget.member.controller!.play();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      print("Video error: ${e.toString()}");
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      widget.member.controller?.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void didUpdateWidget(covariant TeamMemberCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (_isInitialized) {
        widget.member.controller?.play();
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      widget.member.controller?.pause();
    }
  }

  @override
  void dispose() {
    if (!widget.isActive) {
      widget.member.controller?.pause();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: widget.isActive ? 16 : 24,
      ),
      child: Card(
        color: Colors.black.withOpacity(0.7),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.deepPurpleAccent.withOpacity(0.7),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Video Background
            if (_isInitialized && !_hasError)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: widget.member.controller!.value.size.width,
                      height: widget.member.controller!.value.size.height,
                      child: VideoPlayer(widget.member.controller!),
                    ),
                  ),
                ),
              ),

            // Loading Indicator
            if (!_isInitialized && !_hasError)
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            // Error Display
            if (_hasError)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Video unavailable',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

            // Content Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7)
                  ],
                  stops: const [0.0, 0.3, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Profile Image
                    Expanded(
                      flex: 4,
                      child: Hero(
                        tag: widget.member.name,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            widget.member.imageUrl,
                            height: 140,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Member Details
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.member.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.member.title,
                            style: TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.member.quote,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: widget.member.skills.split(',').map((skill) {
                              return Chip(
                                label: Text(
                                  skill.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor:
                                Colors.deepPurpleAccent.withOpacity(0.8),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mute Button
            if (_isInitialized && !_hasError)
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ),
          ],
        ),
      ),
    );
  }
}