<template>
  <v-row justify-center>
    <v-dialog v-model="dialog" max-width="600px">
      <ValidationObserver ref="observer" v-slot="{ invalid }">
        <v-card>
          <v-system-bar class="pa-5 subtitle-1"
            >ハッシュタグを登録する</v-system-bar
          >
          <v-card-text class="mt-5">
            <v-container>
              <v-form @submit.prevent="onSubmit">
                <ValidationProvider
                  ref="provider"
                  v-slot="{ errors }"
                  name="ハッシュタグ"
                  rules="required|tagNameFormat"
                >
                  <v-text-field
                    v-model="tagName"
                    :error-messages="errors"
                    label="ハッシュタグ"
                    hint="#を含めず入力してください"
                    persistent-hint
                    required
                  >
                    <v-icon slot="prepend">mdi-pound</v-icon>
                  </v-text-field>
                </ValidationProvider>
              </v-form>
              <p class="ml-md-10 mt-5">
                登録時に直近1週間のツイートを取得します。<br />ハッシュタグは3つまで登録できます。
              </p>
            </v-container>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn text @click="resetForm">キャンセル</v-btn>
            <v-btn text color="primary" :disabled="invalid" @click="sendTagName"
              >登録する</v-btn
            >
          </v-card-actions>
        </v-card>
      </ValidationObserver>
      <!-- ローディング -->
      <loading-circle v-if="isLoading" />
    </v-dialog>
  </v-row>
</template>

<script>
import loadingCircle from "./shared/TheLoading"

export default {
  components: {
    loadingCircle
  },
  data() {
    return {
      dialog: false,
      tagName: "",
      isLoading: false
    }
  },
  methods: {
    open() {
      this.dialog = true
    },
    resetForm() {
      this.dialog = false
      this.tagName = ""
      this.$nextTick(() => {
        this.$refs.observer.reset()
      })
    },
    async sendTagName() {
      const isValid = await this.$refs.observer.validate()
      // disableにしているから大丈夫のはずだけど、一応バリデーションを通らないとリクエストを送れないようにしている
      if (isValid) {
        try {
          this.isLoading = true
          const registeredTagRes = await this.$axios.post(
            "/api/v1/registered_tags",
            {
              tag: {
                name: this.tagName
              }
            }
          )
          const tagId = registeredTagRes.data.registeredTag.id
          this.$router.push({ name: "myTag", params: { tagId } })
          this.$toTop()
          this.$store.dispatch("flash/setFlash", {
            type: "success",
            message: "ハッシュタグを登録しました"
          })
          this.resetForm()
        } catch (error) {
          const unprocessableEntityStatus = 422
          const tooManyRequestsStatus = 429
          switch (error.response.status) {
            case unprocessableEntityStatus: {
              const errorMessage = error.response.data.error.messages[0]
              this.$refs.provider.errors.push(errorMessage)
              break
            }
            case tooManyRequestsStatus: {
              const errorMessage = error.response.data.error.messages[0]
              this.$refs.provider.errors.push(errorMessage)
              break
            }
            default:
              throw error
          }
        } finally {
          this.isLoading = false
          this.$emit("create-tag")
        }
      }
    }
  }
}
</script>
