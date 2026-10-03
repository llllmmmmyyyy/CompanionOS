import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { preferences } from '@kit.ArkData';
import { http } from '@kit.NetworkKit';
import { validBackendUrl, validMediaUrl } from '@companion/protocol';

export class UserVideo {
  title: string = 'My family video';
  path: string = '';
  durationSeconds: number = 0;
  remoteUrl: string = '';
}
class ImportResponse { videoUrl: string = ''; }
export class UserVideoStore {
  private context: common.UIAbilityContext;
  private prefs: preferences.Preferences;
  constructor(context: common.UIAbilityContext) {
    this.context = context; this.prefs = preferences.getPreferencesSync(context, { name: 'companion_video' });
  }
  load(): UserVideo | undefined {
    try {
      const value = JSON.parse(this.prefs.getSync('video', '') as string) as UserVideo;
      if (!value || typeof value.title !== 'string' || value.title.length > 80 ||
        value.path !== `${this.context.filesDir}/family-video.mp4` || !fs.accessSync(value.path) ||
        !Number.isFinite(value.durationSeconds) || value.durationSeconds <= 0) { return undefined; }
      // A previous backend URL is not proof the remote copy still exists. Upload again for each selection.
      value.remoteUrl = ''; return value;
    } catch { return undefined; }
  }
  async pick(title: string): Promise<UserVideo | undefined> {
    const result = await new photoAccessHelper.PhotoViewPicker().select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE, maxSelectNumber: 1
    });
    if (result.photoUris.length === 0) { return undefined; }
    const source = fs.openSync(result.photoUris[0], fs.OpenMode.READ_ONLY);
    const temporary = `${this.context.filesDir}/family-video-import.mp4`;
    try {
      const size = fs.statSync(source.fd).size;
      if (size < 16 || size > 40 * 1024 * 1024) { throw new Error('Choose an MP4 smaller than 40 MiB.'); }
      const signature = new ArrayBuffer(12); fs.readSync(source.fd, signature, { offset: 0, length: 12 });
      const bytes = new Uint8Array(signature);
      if (bytes[4] !== 102 || bytes[5] !== 116 || bytes[6] !== 121 || bytes[7] !== 112) { throw new Error('Choose an MP4 video.'); }
      fs.copyFileSync(source.fd, temporary);
    } finally { fs.closeSync(source); }
    const extractor = await media.createAVMetadataExtractor();
    const file = fs.openSync(temporary, fs.OpenMode.READ_ONLY);
    let seconds: number = 0;
    try {
      extractor.fdSrc = { fd: file.fd, offset: 0, length: fs.statSync(file.fd).size };
      const metadata = await extractor.fetchMetadata(); seconds = Number(metadata.duration) / 1000;
      if (!Number.isFinite(seconds) || seconds <= 0) { throw new Error('Could not read the video duration.'); }
    } finally { await extractor.release(); fs.closeSync(file); }
    const value = new UserVideo(); value.path = `${this.context.filesDir}/family-video.mp4`;
    value.title = title.trim().slice(0, 80) || 'My family video'; value.durationSeconds = seconds;
    fs.renameSync(temporary, value.path);
    this.prefs.putSync('video', JSON.stringify(value)); await this.prefs.flush(); return value;
  }
  async publish(value: UserVideo, endpoint: string): Promise<string> {
    if (!validBackendUrl(endpoint) || !fs.accessSync(value.path)) { throw new Error('Video or backend unavailable'); }
    const file = fs.openSync(value.path, fs.OpenMode.READ_ONLY);
    const client = http.createHttp();
    try {
      const size = fs.statSync(file.fd).size;
      if (size > 40 * 1024 * 1024 || size < 16) { throw new Error('Invalid video size'); }
      const buffer = new ArrayBuffer(size); const read = fs.readSync(file.fd, buffer);
      if (read !== size) { throw new Error('Video could not be read'); }
      const response = await client.request(`${endpoint}/media/import`, { method: http.RequestMethod.POST,
        header: { 'Content-Type': 'video/mp4' }, extraData: buffer, expectDataType: http.HttpDataType.STRING,
        connectTimeout: 3000, readTimeout: 20000, usingCache: false });
      if (response.responseCode !== 201 || typeof response.result !== 'string') { throw new Error('Video upload failed'); }
      const parsed = JSON.parse(response.result) as ImportResponse;
      const url = `${endpoint}${parsed.videoUrl}`;
      if (!/^\/videos\/[a-f0-9]{64}$/.test(parsed.videoUrl) || !validMediaUrl(url)) { throw new Error('Invalid video URL'); }
      return url;
    } finally { client.destroy(); fs.closeSync(file); }
  }
}
