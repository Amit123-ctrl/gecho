import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import 'post_detail_bottom_sheet.dart';

class PostGridItem extends StatelessWidget {
  final Post post;

  const PostGridItem({super.key, required this.post});

  void _showPostDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailBottomSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPostDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            if (post.imageUrl != null)
              CachedNetworkImage(
                imageUrl: post.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.error)),
                ),
              )
            else
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    post.isBlog ? Icons.article : Icons.photo,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            // Blog content preview overlay
            if (post.isBlog && post.blogContent != null && post.blogContent!.isNotEmpty)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.blogContent!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Post type indicator
            if (post.isBlog)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}