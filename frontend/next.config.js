/** @type {import('next').NextConfig} */

module.exports = {
  reactStrictMode: true,
  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false }
    return config
  },
}

/** @type {import('next').NextConfig} */

module.exports = {
  webpack: (config, { isServer }) => {
    
    patchWasmModuleImport(config, isServer);

    if (!isServer) {
      config.output.environment = { ...config.output.environment, asyncFunction: true };
    }
    return config
    },
    typescript: {
      // !! WARN !!
      // Dangerously allow production builds to successfully complete even if
      // your project has type errors.
      // !! WARN !!
      ignoreBuildErrors: true,
    },
    env: {
      ALCHEMY_API_KEY: process.env.ALCHEMY_API_KEY,
    },
}

function patchWasmModuleImport(config, isServer) {
  config.experiments = Object.assign(config.experiments || {}, {
    asyncWebAssembly: true,
    layers: true,
    topLevelAwait: true
  });

  config.optimization.moduleIds = 'named';

  config.module.rules.push({
    test: /\.wasm$/,
    type: 'asset/resource',
  });

  // TODO: improve this function -> track https://github.com/vercel/next.js/issues/25852
  if (isServer) {
    config.output.webassemblyModuleFilename = './../static/wasm/tfhe_bg.wasm';
  } else {
    config.output.webassemblyModuleFilename = 'static/wasm/tfhe_bg.wasm';
  }
}