/* encryptcontent/decrypt-contents.tpl.js */

function base64url_decode(input) {
    try {
        const binString = atob(input.replace(/-/g, '+').replace(/_/g, '/'));
        const binArray = Uint8Array.from(binString, (m) => m.codePointAt(0));
        return new TextDecoder().decode(binArray);
    }
    catch (err) {
        return false;
    }
}

/* Decrypts the key from the key bundle. */
function decrypt_key(pass, iv_b64, ciphertext_b64, salt_b64) {
    let salt = CryptoJS.enc.Base64.parse(salt_b64),
        kdfcfg = {keySize: 256 / 32,hasher: CryptoJS.algo.SHA256,iterations: encryptcontent_obfuscate ? 1 : 10000};
    let kdfkey = CryptoJS.PBKDF2(pass, salt,kdfcfg);
    let iv = CryptoJS.enc.Base64.parse(iv_b64),
        ciphertext = CryptoJS.enc.Base64.parse(ciphertext_b64);
    let encrypted = {ciphertext: ciphertext},
        cfg = {iv: iv, mode: CryptoJS.mode.CBC, padding: CryptoJS.pad.Pkcs7};
    let key = CryptoJS.AES.decrypt(encrypted, kdfkey, cfg);

    try {
        let keystore = JSON.parse(key.toString(CryptoJS.enc.Utf8));
        if (encryptcontent_id in keystore) {
            return keystore;
        } else {
            //id not found in keystore
            return false;
        }
    } catch (err) {
        // encoding failed; wrong password
        return false;
    }
};

/* Split key bundle and try to decrypt it */
function decrypt_key_from_bundle(password, ciphertext_bundle, username) {
    // grab the ciphertext bundle and try to decrypt it
    let user, pass;
    let parts, keys, userhash;
    if (ciphertext_bundle) {
        if (username) {
            user = encodeURIComponent(username.toLowerCase());
            userhash = CryptoJS.SHA256(user).toString(CryptoJS.enc.Base64);
        }
        for (let i = 0; i < ciphertext_bundle.length; i++) {
            pass = encodeURIComponent(password);
            parts = ciphertext_bundle[i].split(';');
            if (parts.length == 3) {
                keys = decrypt_key(pass, parts[0], parts[1], parts[2]);
                if (keys) {
                    
                    return keys;
                }
            } else if (parts.length == 4 && username) {
                if (parts[3] == userhash) {
                    keys = decrypt_key(pass, parts[0], parts[1], parts[2]);
                    if (keys) {
                        
                        return keys;
                    }
                }
            }
        }
    }
    return false;
};

/* Decrypts the content from the ciphertext bundle. */
function decrypt_content(key, iv_b64, ciphertext_b64) {
    let iv = CryptoJS.enc.Base64.parse(iv_b64),
        ciphertext = CryptoJS.enc.Base64.parse(ciphertext_b64);
    let encrypted = {ciphertext: ciphertext},
        cfg = {iv: iv, mode: CryptoJS.mode.CBC, padding: CryptoJS.pad.Pkcs7};
    let plaintext = CryptoJS.AES.decrypt(encrypted, CryptoJS.enc.Hex.parse(key), cfg);
    if(plaintext.sigBytes >= 0) {
        try {
            return plaintext.toString(CryptoJS.enc.Utf8)
        } catch (err) {
            // encoding failed; wrong key
            return false;
        }
    } else {
        // negative sigBytes; wrong key
        return false;
    }
};

/* Split cyphertext bundle and try to decrypt it */
function decrypt_content_from_bundle(key, ciphertext_bundle) {
    // grab the ciphertext bundle and try to decrypt it
    if (ciphertext_bundle) {
        let parts = ciphertext_bundle.split(';');
        if (parts.length == 2) {
            return decrypt_content(key, parts[0], parts[1]);
        }
    }
    return false;
};

/* Save decrypted keystore to sessionStorage */
function setKeys(keys_from_keystore) {
    for (const id in keys_from_keystore) {
        sessionStorage.setItem(id, keys_from_keystore[id]);
    }
};

/* Delete key with specific name in sessionStorage */
function delItemName(key) {
    sessionStorage.removeItem(key);
};

function getItemName(key) {
    return sessionStorage.getItem(key);
};

/* Reload scripts src after decryption process */
function reload_js(src) {
    let script_src, script_tag, new_script_tag;
    let head = document.getElementsByTagName('head')[0];

    if (src.startsWith('#')) {
        script_tag = document.getElementById(src.substr(1));
        if (script_tag) {
            script_tag.remove();
            new_script_tag = document.createElement('script');
            if (script_tag.innerHTML) {
                new_script_tag.innerHTML = script_tag.innerHTML;
            }
            if (script_tag.src) {
                new_script_tag.src = script_tag.src;
            }
            if (script_tag.type) {
                new_script_tag.type = script_tag.type;
            }
            head.appendChild(new_script_tag);
        }
    } else {
        if (base_url == '.') {
            script_src = src;
        } else {
            script_src = base_url + '/' + src;
        }

        script_tag = document.querySelector('script[src="' + script_src + '"]');
        if (script_tag) {
            script_tag.remove();
            new_script_tag = document.createElement('script');
            new_script_tag.src = script_src;
            head.appendChild(new_script_tag);
        }
    }
};



/* Decrypt speficique html entry from mkdocs configuration */
function decrypt_somethings(key, encrypted_something) {
    var html_item = '';
    for (const [name, tag] of Object.entries(encrypted_something)) {
        if (tag[1] == 'id') {
            html_item = [document.getElementById(name)];
        } else if (tag[1] == 'class') {
            html_item = document.getElementsByClassName(name);
        } else {
            console.log('WARNING: Unknow tag html found, check "encrypted_something" configuration.');
        }
        if (html_item[0]) {
            for (let i = 0; i < html_item.length; i++) {
                // grab the cipher bundle if something exist
                if (html_item[i].style.display == "none") {
                    let content = decrypt_content_from_bundle(key, html_item[i].innerHTML);
                    if (content !== false) {
                        // success; display the decrypted content
                        html_item[i].innerHTML = content;
                        html_item[i].style.display = null;
                        // any post processing on the decrypted content should be done here
                    }
                }
            }
        }
    }
    return html_item[0];
};

/* Decrypt content of a page */
function decrypt_action(username_input, password_input, encrypted_content, decrypted_content, key_from_storage=false) {
    let key=false;
    let keys_from_keystore=false;

    let user=false;
    if (username_input) {
        user = username_input.value;
    }

    if (key_from_storage !== false) {
        key = key_from_storage;
    } else {
        keys_from_keystore = decrypt_key_from_bundle(password_input.value, encryptcontent_keystore, user);
        if (keys_from_keystore) {
            key = keys_from_keystore[encryptcontent_id];
        }
    }

    let content = false;
    if (key) {
        content = decrypt_content_from_bundle(key, encrypted_content.innerHTML);
    }
    if (content !== false) {
        // success; display the decrypted content
        decrypted_content.innerHTML = content;
        encrypted_content.parentNode.removeChild(encrypted_content);

        if (keys_from_keystore !== false) {
            return keys_from_keystore
        } else {
            return key
        }
    } else {
        return false
    }
};

function decryptor_reaction(key_or_keys, password_input, decrypted_content, fallback_used=false) {
    if (key_or_keys) {
        let key;
        if (typeof key_or_keys === "object") {
            key = key_or_keys[encryptcontent_id];
            setKeys(key_or_keys);
            
        } else {
            key = key_or_keys;
        }

        // continue to decrypt others parts
        
        if (typeof inject_something !== 'undefined') {
            decrypted_content = decrypt_somethings(key, inject_something);
        }
        if (typeof delete_something !== 'undefined') {
            let el = document.getElementById(delete_something)
            if (el) {
                el.remove();
            }
        }

        // any post processing on the decrypted content should be done here
        if (typeof MathJax === 'object') { MathJax.typesetPromise();};
        
        decrypted_content.querySelectorAll('pre code').forEach((block) => {
            hljs.highlightElement(block);
        });
        
        if (typeof theme_run_after_decryption !== 'undefined') {
            theme_run_after_decryption();
        }
        if (window.location.hash) { //jump to anchor if hash given after decryption
            window.location.href = window.location.hash;
        }
    } else {
        // remove item on sessionStorage if decryption process fail (Invalid item)
        if (!fallback_used) {
            if (!encryptcontent_obfuscate) {
                // create HTML element for the inform message
                let mkdocs_decrypt_msg = document.getElementById('mkdocs-decrypt-msg');
                mkdocs_decrypt_msg.textContent = decryption_failure_message;
                password_input.value = '';
                password_input.focus();
            }
        }
        delItemName(encryptcontent_id);
    }
}

/* Trigger decryption process */
function init_decryptor() {
    let username_input = document.getElementById('mkdocs-content-user');
    let password_input = document.getElementById('mkdocs-content-password');
    // adjust password field width to placeholder length
    //if (password_input.hasAttribute('placeholder')) {
    //    password_input.setAttribute('size', password_input.getAttribute('placeholder').length);
    //}
    let encrypted_content = document.getElementById('mkdocs-encrypted-content');
    let decrypted_content = document.getElementById('mkdocs-decrypted-content');
    let content_decrypted;
    /* If remember_keys is set, try to use sessionStorage item to decrypt content when page is loaded */
    let key_from_storage = getItemName(encryptcontent_id);
    if (key_from_storage) {
        content_decrypted = decrypt_action(
            username_input, password_input, encrypted_content, decrypted_content, key_from_storage
        );
        
        decryptor_reaction(content_decrypted, password_input, decrypted_content, true);
    }
    
    /* If password_button is set, try decrypt content when button is press */
    let decrypt_button = document.getElementById("mkdocs-decrypt-button");
    if (decrypt_button) {
        decrypt_button.onclick = function(event) {
            event.preventDefault();
            content_decrypted = decrypt_action(
                username_input, password_input, encrypted_content, decrypted_content
            );
            decryptor_reaction(content_decrypted, password_input, decrypted_content);
        };
    }
    /* Default, try decrypt content when key enter is press */
    password_input.addEventListener('keypress', function(event) {
        if (event.key === "Enter") {
            event.preventDefault();
            content_decrypted = decrypt_action(
                username_input, password_input, encrypted_content, decrypted_content
            );
            decryptor_reaction(content_decrypted, password_input, decrypted_content);
        }
    });
}
if (typeof base_url === 'undefined') {
    var base_url = JSON.parse(document.getElementById('__config').textContent).base;
}
if (document.readyState === "loading") {
  // Loading hasn't finished yet
  document.addEventListener("DOMContentLoaded", init_decryptor);
} else {
  // `DOMContentLoaded` has already fired
  init_decryptor();
}
window["init_decryptor"] = init_decryptor;