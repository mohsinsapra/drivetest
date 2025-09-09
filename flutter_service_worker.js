'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "9d9a424e19c5608c58647c97fd0b2bf9",
"version.json": "0acafe4f44afe9e163d399cbb5229d6e",
"index.html": "69fcb0527a2000ccf98251131d8139b7",
"/": "69fcb0527a2000ccf98251131d8139b7",
"main.dart.js": "680033611a355d3095feb4204e16e302",
"web.config": "f69a32c9405dde9a1f1efc2cecbde26b",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "9d6f9e5b2d58c5b8d34d5772231522ac",
".git/config": "9e5376a86dc147a84cf588355e3a7996",
".git/objects/61/29ed611698c430e091001fd1f1c27d0856c03f": "ea16b0209d70ae980b09eee2fb2ada8f",
".git/objects/92/7b696064ba2343ab9714aba5818a2d93aec339": "1dfa854be3de7ea92a7022ee6607cbc1",
".git/objects/0c/fc276e170a8714920ece9a592b53c2505e2c7a": "7b8455a4632cedb1275ade221c8ff7db",
".git/objects/66/ebe3c5acd21e4b9195679da98a1c970c690d73": "b677c74d3e178a3cf7a525ba775034ff",
".git/objects/3b/83cc41421027d6fd4821203df9795d249f4091": "8f383045d05acc2498209dbdc19f4b3a",
".git/objects/3b/eb7890b45ca2875195243c4d7b8090b4f2549e": "7ad1148a6be26d6dc597bf1d110c6ccb",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9e/df8ae680a6c8110691a28ff37059826fd4f5c6": "3ded97bea27a8079d2bc58f26c7e99e4",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/32/38862b0385113969e045d1f9b891dc52c5658d": "c1db57c77f559ca6daf844f2ac568185",
".git/objects/35/f60e5df36e4a222291d15cb1d7a111d4e94ead": "e082b27771269626563792ec5865d9db",
".git/objects/35/a1f1cccca0869c75e4b3d4095f8e45c3c9a651": "121867a35bb576786bce96514cfe16a1",
".git/objects/35/4e657bff4a6bc60b3fc37f1637b866dc2ccb08": "e20f44e1f4321b652d7ee24654d204e6",
".git/objects/69/7612b856b42c7df2f6b11a751697ce3fb59ba5": "eb2c167bd5d2090211aac5d103a33a2d",
".git/objects/56/5e18b8caaf69d64513527b5db56660994f54fd": "e3de962bf71d16ee4e991ee7eb17dcaa",
".git/objects/56/144ad1679cd915eb2f205ac86faa6899ceeae6": "0120240ed0cb56a905a100fcdffa2954",
".git/objects/3d/1b8ed8e463ae6965c3145777e567e072e99ae6": "7f9420612beb3070dfe9629a4de1b7bf",
".git/objects/67/380c60f4282a6489cc21c6fde7b398fcd89871": "9f60b5f42519e393567830780c5aecec",
".git/objects/0b/ec7537357f34c386e9c0e2a7473dcf2a2b575d": "338b04cded33447757533a0b05d874ed",
".git/objects/0b/540c0e227761ed01991d41e584af8af7e632c6": "110ce2d7f73fac8ddb63c026ca616699",
".git/objects/94/fa363e7c95f67e168e58ded2d9978b6d76e2a2": "5fb547781b0eba2e0758bd5ea967972b",
".git/objects/0e/c05a158a7d95f0c10831fcda3e92aa55f66a8e": "c69b05bbc815920632826e48822c9c92",
".git/objects/5a/33b2cf863d80b7b08881e3deb1ad5cdc954c43": "cc5bb952358cd942f3ae2b4ef8f17053",
".git/objects/b5/698a9e0dd6eda9537bc1961dcb8e3e0f581a7f": "20df0ea4fb103787cd27d54c8228cb64",
".git/objects/b2/42de73c7025898a4d6ea57b9082eb341184bcd": "d679e64cbe3e7992a4852898bcb07c5c",
".git/objects/b2/906c8aac662742ffce3faf9aeb704e9ccb0102": "48e9399d5d1a3bc62446a1be3ce6026c",
".git/objects/d7/6060c8f603defdb60baa69ec07ae3c00782823": "e453fca0791162133bf96ce9005b4135",
".git/objects/da/41923d7e45d12186d1eb9a0a60cc1bf373192a": "4e8133dd1a790d71c8fa77eac9e0f3f3",
".git/objects/da/0d5aa44a8c93eda469f7a99ed8feac32d5b19d": "25d25e93b491abda0b2b909e7485f4d1",
".git/objects/b4/09271e77d92c122d9ec04d6c19e42ab3b64328": "dd6bde98d1957c7f4acdb40c71e711fc",
".git/objects/a5/2a1bc0370d403a7534d5e1e61f60f6e4d01cb3": "dc6574c8439ce2a94c1c494beaf305cb",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/bc/b828e18534e5b64097a97a11c237ed4b0e929f": "9993d04391444ed7b2f5fb8168d70b76",
".git/objects/ae/0433d21ae0a522aea506fd90eeb275d3d3e17c": "e17936a288a12ed325108b6c16575b22",
".git/objects/d8/8128adaad90d2fd7cdabe7b36eaaaed0d3a25b": "3d15963af0d77c1cd40702fb7c18fa93",
".git/objects/f4/7a638c481771da11ff9f841e7e8b9d42109f58": "e37e2f05fc686997e2dd4088e3d32daa",
".git/objects/f3/00daa08711f088049c65eadd47ed9af78af28b": "ac35ef9d056367fe8ae538b2594a9c6c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/eb/754099f4d3067eab1d1e9c3388188ab6bea9a8": "be9bfea88c1ca688b5833fd3e584b6ea",
".git/objects/c7/0b100a3e931a84b061489fea2779cfe28d73d3": "d5a961ea0cfdacc644ec611b7760e28e",
".git/objects/c0/7395009fa744079e2c24d04d8adc5fa29f1fa2": "b73a3641f1d9842413beabf77f22a81d",
".git/objects/c0/e0ce6f5ed1721bf1a5863d91737676040f6230": "04f4be489f90c50046c5a61b3a0b6a01",
".git/objects/ee/ab0b697b459d61dc75ac28e5180e2214e01ba5": "d61df6f634d557604ea524535d4ce05d",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/e3/893d874f83726c7faee6b44a20e3f501a947cf": "018c2070207c5adf1a0677acd0bd09fc",
".git/objects/e3/74048f1f6a288f25168e3706764bf61e86e830": "2c34c4483b25936d423d3e6fbd37e9a4",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/fb/c1c7f2cec81ee0aeed3643205113359d4e47fd": "b52b412ffa7d4adebc690e8145110447",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/ed/e36649bb4fe084356bac52bf6af15802e1c61e": "997985fabb161f71e6f4eb39ff34669a",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/20/bf247cce6a42cd8827684e135150c2e16841e9": "7238c3da58b57920fb98be78714998a4",
".git/objects/20/46f1db78dcf168496c79812321224600b67a21": "d7d44f9877bdf2797972e73d63e6fb8d",
".git/objects/27/521b397b778367094a944d750949243b8dc5da": "d93fa0617fbc69b9f625e4544998354c",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/29/f4a47a7848291df0fffbccdf63183e9aae6baa": "9919ff45e3f4e55037e6d6c75c6547a4",
".git/objects/42/a2dc9640b484e0494031269d4ad34da070b06d": "9077367b104e6cf7500b501bf39839eb",
".git/objects/45/1e20b64ab3a17a18ca4af0599938d35785ad7b": "3118e1a6e18e73550891552b39fe88c7",
".git/objects/45/19931ca18a5047d753709b4ebb5fafd534d6c1": "2e59de16dda1fdb4208261260c02de7d",
".git/objects/45/db1c713a163a9fc2106b88865b9a902c114067": "bd12a526072ff610f6307cbb343ae290",
".git/objects/28/e9d99fc020b0581fdbc70cf042b33206e38358": "aa77c116ce9a55e9417ada2ec4cc1461",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/10/6ea8053483616d99195fa46446d4eeb76d810e": "719d35db6aa5a2f17dda2052bb1016c9",
".git/objects/10/9e09162ca13a58688826bdba02799a2807377e": "1cbece680724604d8d9a5827bdb62a2d",
".git/objects/19/83488e22ec95825974f4906083beb9c4278b34": "d75c4d3770484e7a4d29a7f06cd46a50",
".git/objects/21/40d837e0e892ef4c88b0c9555fae23fdd0d81e": "e882a5859f6d50218002065f74825719",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4d/fabc78c833f0d37979e8b50ddf46c96fcec46f": "0beddb6a2f83da869ba820c5d24e8e7d",
".git/objects/75/42c6b0e9cdcf9c8e3f7da12ab5edf7415f9fad": "f31e0e5a82c78b71792ba19b15f96867",
".git/objects/81/fc5f32eb84392887a54ade4c1afed38d71e4dd": "1114767e410fbed3ca3d51e01425fb00",
".git/objects/72/ada6baac9193047a04d1ef7fc6c08c19a0aad4": "515cf0496f523efb00e1cdbca48aebe4",
".git/objects/72/80bdddbc17dfe709057953d0753e5ffd0f0f2e": "ba56b40d645a0f16807ab3de83ab0ea1",
".git/objects/2f/ad007c41c9a1af14729eb6c55b3be988ccd70e": "1712b2e9acee7cc15a8d7ccdae0f6b04",
".git/objects/43/a807429b8feca10081ce3bfa414e73236839b1": "cc00850ed693f79a25bdc1cdeb47e52a",
".git/objects/43/abc3fe2fbc220e25d400599254199cc403f42a": "019a791813a6baa0b8b984e65ae9c16f",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/9f/ce13f269d32a589ec7f30ef6655765bb64772c": "28ec489fb323784667669ec33b7191a2",
".git/objects/5c/a017893b2927c9a549a678278c883a97ef2a0d": "ae6097befff3fad1d76396cd065264d6",
".git/objects/09/245d76fd7d561a5ac3d2afaa1d2aa423e1d67a": "e9b1ecaf27da2041b8f7c5d0ccf0df7b",
".git/objects/09/ab645bdd42c058cd903e13967cfe2ca3f72433": "c7c3f54b3b1af209e16b2ccd44366131",
".git/objects/5d/58b3f5f6eef36a83c16b3ee49f05f23e5a29e0": "9d94f67124959cf25684ba02c15fa6d2",
".git/objects/54/f18b7991d0807afedde69a751c02da7ffb486c": "68b23a51eef52da56757774c46b06a1c",
".git/objects/98/edd56833304e535cf5190cc59ae49c514cdeb8": "e1ef75bc0a07006bc193fdcb9bc92f97",
".git/objects/98/9d095a36c466bc1cb6844a8ed647039f2ca6e8": "2b8aa637edbf2b27096464ec10955331",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/6d/3e683ed5bcfd0746449736b90985c96366fc8f": "24bc8f12788d72a1994fa4c8d312af71",
".git/objects/01/2661b5f9c93afed3a9abe9d3804e8b31c1b9f5": "4a617502c51620baf3132d1ad0baedb2",
".git/objects/06/b63f9dab4b1fa64ff9745d64e16b6296914273": "599eca558894cf2e4c056e3584557de0",
".git/objects/06/bf1484b539d0bb13cfb109f08ceb635f7a4b17": "89daa17750db61c3ed19ea8cc605c32e",
".git/objects/52/f11cf6ea13e2b361cbca85bf331edaa7e2a8dc": "d0c4a5089f05892c2fd92b666e592037",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/58a3b6c2b9708c9d85bc9d484e77ced777457a": "e28cd595c75e9c4471f0a63fef152418",
".git/objects/a7/97eec72688701b7de5c2648240fa773a50ec61": "04c08ba524ed4df81bb4671605de6f05",
".git/objects/b1/8dc314f250774da3096b876e9a5b6e3b6896c4": "47f87b4ba3f37ac14490f01fca7af875",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/aa/71b652a91277c61980ad7c94ebf8213e70cfa1": "9a33a7f98b070a07e9e99468662fb7fb",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/db/b157653bb2be559436d491070dce6eed434714": "6a69d237d232d8bd91c2982bf2a6f54a",
".git/objects/db/a241c175bac36f71b4ff09852406b03a33ab4c": "bcf73d18fc155c44a447a97bdcba9916",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/a1/1aedb3fbc1744dc90506a21661c03f19f3c13f": "f033009e31be6c3394bef04c87b54872",
".git/objects/a1/ab37c92d4ae397abcdc51e1cb30a067a6c1333": "09d920e6b4a6b99dcc1d9b60cefb66f0",
".git/objects/c3/1fd0b25f5c8111443b008bdb344a4b8495b4f9": "6a5802fd93c23b446375be0361b55c08",
".git/objects/c3/a015209dd1ecf055bc15ea4d2f65f37a2abbfd": "20e38cb48c14819a255ddf298fd56a49",
".git/objects/c4/ebad28239876de1b986a2427376b077c1a0220": "c7098e473a1fff4a06cf5b48046ed03b",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/cc/f6f22b35087b56e91d0ad8af0cd1c208c7fcb8": "d050a104a769f18e277203d8ef6f01a1",
".git/objects/cc/09c7f5fcf313453eca24f8ceec4f8fbfc1d225": "9461d3028da79a0612a5279bb9791892",
".git/objects/cc/c2093fa53f46e12c24dd582deb8d47f2faf962": "745697e873c42e4c0a3e90c0b1268b7b",
".git/objects/e6/a4abbb448657c6521c1661dc88e762ec61129b": "e29521411cafdaef24b412bc13236952",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/f0/f9562dedac79ae1477f384e1b906031786695b": "ca70889c33d9d012d89b48b23e501534",
".git/objects/f0/5e37ac83db389d25c1897d0721b97bd8e00869": "695a6a49c8629fa5859ba2fc3b3cae43",
".git/objects/c5/d451b768a41808d9a768adb4e15821035291b6": "e4de8e854e2431c065fbb68e2c6e340f",
".git/objects/cb/31adba1b6c42be0a62285c8e63306c4c3b6ad9": "d2dbad19efc97e5c83fe2f3cbbf44c14",
".git/objects/cb/9221053157e2c021da360e46d1407a52a341e2": "76758ab453f189cba8aa3a6b4919b757",
".git/objects/e0/1348abec1b125b8b6f07ca2bb147f77f40f782": "6c606c32187578c24ed53e54001c8451",
".git/objects/2c/97f18bbfc6a181a9f3cd3a89f2635162fd87f5": "7123cdc3a91e6baeb5656032279668d7",
".git/objects/2c/ed52bdebdd28de483ca997126b61ad69527519": "cb0df189512ba7f4fba6cf7606fc142c",
".git/objects/1b/80f0f1a7235fbbb5af6de6f9b6663f544164ca": "fb72f9a73872ea4ea164079cb16ecd11",
".git/objects/77/27824272d72851db4f3a488d98b280ae63ffe5": "5c1b3f45de2175a9a771c162199fb384",
".git/objects/77/d855bb2d1691c25390376700a1a9066f1d5f0b": "8f30661c4307af66efcb98c8f80f88f7",
".git/objects/48/5026b8f5c9fdb877033a9c1840105051b76623": "f6ac4c3261b4b257ef988e6131b1b9da",
".git/objects/70/6b89226856a184964d4ef26acca4690f34feb3": "b47861a6de6336cfde49244ec049778b",
".git/objects/70/0c853c02e5ee010542028bcdb51c9abe308cbf": "7a01ac3fb1acbca110524aa64c9b222d",
".git/objects/70/b527f06b7f8a7e01c59edde6f6baa40fd3840d": "1d601b29ea004a9a334c148a5740efb8",
".git/objects/1e/36a8d2ec0f545a4bdcf80d174a9e06b29d7e73": "7bd62d1fe012096fc641004cbd878112",
".git/objects/1e/a14eb5dd005ae1e7f4240b9fa47b36e647a581": "4fc462d45f4bfc70d0b5d4c5e9368269",
".git/objects/4a/6d56e939b38fe1d595ac354489663fc48d143f": "e52c1260cb56bcbdf40983f3f958aa32",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/71/73205ac01588b51f0d8330ce0c553ca8837860": "e3290827016e242494c2aa2a4df9bf8d",
".git/objects/82/70338e4efaed451961d24f900137c9dd9a13df": "32b4b063274d8eabe783b881683d591e",
".git/objects/40/e1cf8afad45e425ecf598bab487b5bbcec11c6": "f4c912e8d762be74ae9a3ec27ecff370",
".git/objects/13/c233cfb8ec1875dc458c85c170d6a692a961f6": "3f61de00847c0544311f3b21ec00d2f5",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7a/83d93067af0e8ecf85d8345dfd2a6cb3f6c1cc": "2b7e390485cb607f257fda08807563ad",
".git/objects/8e/8dc088cc6a39aef1644ea6a78ecb962858dbfa": "d8acc771fcc797f2134845439fd7433a",
".git/objects/22/5744bd6947df637fa2f5dbcc5e7c0dea0a6aa1": "9a92957b4a8b60d7f510b1a0baaae628",
".git/HEAD": "4cf2d64e44205fe628ddd534e1151b58",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "35d1d724fba5e009e9856295d4a712b4",
".git/logs/refs/heads/master": "35d1d724fba5e009e9856295d4a712b4",
".git/logs/refs/remotes/origin/master": "d42042c9eabe08e77c17393031bac6d6",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/master": "568e4e5f598ba16516d8c3a29bba31a4",
".git/refs/remotes/origin/master": "568e4e5f598ba16516d8c3a29bba31a4",
".git/index": "5e5e03f54e24788b35f9f97c683ef23a",
".git/COMMIT_EDITMSG": "1a71c35ebb59af06141b41a6e7439019",
"assets/AssetManifest.json": "3c2bbf3fcea02d0568cbbc448797753f",
"assets/NOTICES": "bb9947077d71fcafe17f749e388f2e42",
"assets/FontManifest.json": "6e11893482d18571de905f0702c512f3",
"assets/AssetManifest.bin.json": "f24642d85500c8e8cbaee0db0ef8146c",
"assets/packages/youtube_player_flutter/assets/speedometer.webp": "50448630e948b5b3998ae5a5d112622b",
"assets/packages/lucide_icons/assets/lucide.ttf": "03f254a55085ec6fe9a7ae1861fda9fd",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "db1c4787c61b3fbf749ad996b7c379ce",
"assets/fonts/MaterialIcons-Regular.otf": "8961f78d638888aa494baa2eb8774e71",
"assets/assets/icon/icon.png": "84b049cb04fc50735b118afad7db1fbc",
"assets/assets/fonts/NudMotoya.ttf": "90ac3b18aaef9f2db3ac8e062c7a033b",
"assets/assets/animations/signup.json": "fb1c12206aa9cc382089c31230c6e35f",
"assets/assets/animations/animation1.json": "bc9cf05ae2fcb05e4fbf468b1d7945a8",
"assets/assets/animations/no_attempts.json": "6c6367efadbfbc3967ea0c88f52a9204",
"assets/assets/animations/welcome.json": "11bca123b655934b232647c2e218ad51",
"assets/assets/animations/no_attempts.lottie": "33c54457309b40e6b5f8f76f537bce60",
"assets/assets/animations/login.json": "fba481320f12d66450dda292b752b669",
"assets/assets/animations/animation2.json": "a36fec40317c489c29a96f2c52b05e15",
"assets/assets/animations/animation3.json": "f64e7961489e4f91a0a5de8240c2e813",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
